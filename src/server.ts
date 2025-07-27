import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { z } from 'zod';
import { BlandClient } from './bland-client';
import { CallRequest, BlandWebhookPayload, CallResult } from './types';
import RightmoveScraper from './rightmove-scraper';
import { SearchOptions } from './scraper-types';
import fs from 'fs/promises';
import path from 'path';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const BLAND_API_KEY = process.env.BLAND_API_KEY!;
const BLAND_PHONE_NUMBER = process.env.BLAND_PHONE_NUMBER!;
const WEBHOOK_URL = process.env.WEBHOOK_URL || `http://localhost:${PORT}/webhook/bland`;

const blandClient = new BlandClient(BLAND_API_KEY, BLAND_PHONE_NUMBER, WEBHOOK_URL);
const scraper = new RightmoveScraper();

// In-memory storage for call results (use a database in production)
const callResults = new Map<string, CallResult>();

// Validation schemas
const PropertySchema = z.object({
  id: z.string(),
  address: z.string(),
  price: z.string(),
  bedrooms: z.number(),
  bathrooms: z.number(),
  agentPhone: z.string().optional(),
  agentName: z.string().optional(),
  propertyUrl: z.string(),
  rightmoveId: z.string().optional()
});

const CallRequestSchema = z.object({
  properties: z.array(PropertySchema),
  userId: z.string().optional(),
  notificationEmail: z.string().email().optional()
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Search properties endpoint
app.post('/search-properties', async (req, res) => {
  try {
    const options: SearchOptions = req.body;
    
    // Validate search options
    const validation = scraper.validateSearchOptions(options);
    if (!validation.isValid) {
      return res.status(400).json({ 
        error: 'Invalid search options', 
        details: validation.errors 
      });
    }

    console.log('Searching properties with options:', options);
    const results = await scraper.searchProperties(options);
    
    // Format properties for API response
    const formattedProperties = results.properties.map(property => ({
      id: property.id.toString(),
      address: property.displayAddress,
      price: property.price?.displayPrices?.[0]?.displayPrice || 'Price on request',
      bedrooms: property.bedrooms || 0,
      bathrooms: property.bathrooms || 0,
      propertyUrl: property.propertyUrl,
      rightmoveId: property.id.toString(),
      summary: property.summary,
      images: property.images?.slice(0, 3) || [], // First 3 images
      location: property.location,
      brand: property.brand?.brandTradingName
    }));

    res.json({
      success: true,
      total: results.total,
      pages: results.pages,
      properties: formattedProperties
    });

  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({ 
      error: 'Failed to search properties',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Get available locations
app.get('/locations', (req, res) => {
  res.json({
    locations: scraper.getAvailableLocations()
  });
});

// Initiate calls for properties
app.post('/call-properties', async (req, res) => {
  try {
    const validatedData = CallRequestSchema.parse(req.body);
    const results = [];
    const errors = [];

    // Filter properties with phone numbers
    const callableProperties = validatedData.properties.filter(p => p.agentPhone);
    
    if (callableProperties.length === 0) {
      return res.status(400).json({ 
        error: 'No properties with agent phone numbers provided' 
      });
    }

    // Initiate calls with delay between each
    for (const property of callableProperties) {
      try {
        console.log(`Calling property: ${property.address}`);
        const callResponse = await blandClient.callProperty(property);
        
        results.push({
          propertyId: property.id,
          address: property.address,
          callId: callResponse.call_id,
          status: 'initiated'
        });

        // Wait 5 seconds between calls to avoid overwhelming
        if (callableProperties.indexOf(property) < callableProperties.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 5000));
        }
      } catch (error) {
        console.error(`Failed to call property ${property.id}:`, error);
        errors.push({
          propertyId: property.id,
          address: property.address,
          error: error instanceof Error ? error.message : 'Unknown error'
        });
      }
    }

    res.json({
      success: true,
      initiated: results.length,
      failed: errors.length,
      results,
      errors
    });

  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid request data', details: error.errors });
    }
    console.error('Error processing call request:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Webhook endpoint for Bland.ai callbacks
app.post('/webhook/bland', async (req, res) => {
  try {
    const webhook: BlandWebhookPayload = req.body;
    console.log('Received webhook for call:', webhook.call_id);

    // Extract viewing information from the transcript
    const viewingSlots = extractViewingSlots(webhook.transcript);
    const propertyAvailable = detectAvailability(webhook.transcript);

    // Create call result
    const callResult: CallResult = {
      callId: webhook.call_id,
      propertyId: webhook.variables?.property_id || 'unknown',
      propertyAddress: webhook.variables?.property_address || 'unknown',
      agentPhone: webhook.to,
      status: webhook.error_message ? 'failed' : 'completed',
      duration: webhook.call_length,
      summary: webhook.summary,
      transcript: webhook.transcript,
      recordingUrl: webhook.recording_url,
      viewingSlots,
      propertyAvailable,
      timestamp: new Date()
    };

    // Store result
    callResults.set(webhook.call_id, callResult);

    // Save to file for persistence
    await saveCallResult(callResult);

    res.status(200).json({ received: true });
  } catch (error) {
    console.error('Webhook processing error:', error);
    res.status(500).json({ error: 'Failed to process webhook' });
  }
});

// Get call results
app.get('/call-results', (req, res) => {
  const results = Array.from(callResults.values());
  res.json({
    total: results.length,
    results: results.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
  });
});

// Get specific call result
app.get('/call-results/:callId', (req, res) => {
  const result = callResults.get(req.params.callId);
  if (!result) {
    return res.status(404).json({ error: 'Call result not found' });
  }
  res.json(result);
});

// Helper functions
function extractViewingSlots(transcript: string): string[] {
  const slots: string[] = [];
  
  // Look for common patterns in transcript
  const patterns = [
    /(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)[\s\w]*at[\s\w]*\d{1,2}(?::\d{2})?(?:\s*(?:am|pm))?/gi,
    /\d{1,2}(?::\d{2})?(?:\s*(?:am|pm))[\s\w]*(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)/gi,
    /(?:tomorrow|next week)[\s\w]*at[\s\w]*\d{1,2}(?::\d{2})?(?:\s*(?:am|pm))?/gi
  ];

  patterns.forEach(pattern => {
    const matches = transcript.match(pattern);
    if (matches) {
      slots.push(...matches);
    }
  });

  return [...new Set(slots)]; // Remove duplicates
}

function detectAvailability(transcript: string): boolean {
  const unavailablePhrases = [
    'no longer available',
    'already let',
    'already rented',
    'not available',
    'under offer',
    'deposit taken'
  ];

  const lowerTranscript = transcript.toLowerCase();
  return !unavailablePhrases.some(phrase => lowerTranscript.includes(phrase));
}

async function saveCallResult(result: CallResult): Promise<void> {
  const resultsDir = path.join(__dirname, '..', 'call-results');
  await fs.mkdir(resultsDir, { recursive: true });
  
  const filename = `${result.callId}_${new Date().toISOString().split('T')[0]}.json`;
  const filepath = path.join(resultsDir, filename);
  
  await fs.writeFile(filepath, JSON.stringify(result, null, 2));
}

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Webhook URL: ${WEBHOOK_URL}`);
  console.log('Ready to make property calls!');
});