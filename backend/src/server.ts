/**
 * Live Search API Server
 * HTTP server for property search and details endpoints
 */

import 'dotenv/config';
import * as http from 'http';
import { RightmoveAPI } from './api';
import { SupabaseService } from './services/supabase';
import { PropertySearchParams, PropertyWithDetails } from './types';

const PORT = process.env.PORT || 3001;

const api = new RightmoveAPI();
const supabase = new SupabaseService();

// ===========================================
// Request Handlers
// ===========================================

interface SearchRequest {
  latitude: number;
  longitude: number;
  minPrice?: number;
  maxPrice?: number;
  minBedrooms?: number;
  maxBedrooms?: number;
  minBathrooms?: number;
  maxBathrooms?: number;
  radius?: number;
  furnishType?: string;
  page?: number;
}

interface OnboardingSearchRequest extends SearchRequest {
  queryId: string;  // The saved search query ID to link properties to
}

async function handleSearch(body: SearchRequest) {
  let furnishType: 'furnished' | 'unfurnished' | undefined;
  if (body.furnishType === 'furnished') {
    furnishType = 'furnished';
  } else if (body.furnishType === 'unfurnished') {
    furnishType = 'unfurnished';
  }

  const params: PropertySearchParams = {
    latitude: body.latitude,
    longitude: body.longitude,
    minPrice: body.minPrice,
    maxPrice: body.maxPrice,
    minBedrooms: body.minBedrooms,
    maxBedrooms: body.maxBedrooms,
    minBathrooms: body.minBathrooms,
    maxBathrooms: body.maxBathrooms,
    radius: body.radius,
    furnishType,
    page: body.page || 1,
    pageSize: 25
  };

  const results = await api.searchProperties(params);

  return {
    properties: results.properties,
    total: results.total,
    hasMore: results.hasMore,
    page: results.page
  };
}

/**
 * Handle onboarding search - fetches properties, gets HD images, saves to Supabase
 */
async function handleOnboardingSearch(body: OnboardingSearchRequest) {
  console.log('\n--- Onboarding Search ---');
  console.log('Query ID:', body.queryId);
  console.log('Location:', body.latitude, body.longitude);

  let furnishType: 'furnished' | 'unfurnished' | undefined;
  if (body.furnishType === 'furnished') {
    furnishType = 'furnished';
  } else if (body.furnishType === 'unfurnished') {
    furnishType = 'unfurnished';
  }

  const params: PropertySearchParams = {
    latitude: body.latitude,
    longitude: body.longitude,
    minPrice: body.minPrice,
    maxPrice: body.maxPrice,
    minBedrooms: body.minBedrooms,
    maxBedrooms: body.maxBedrooms,
    minBathrooms: body.minBathrooms,
    maxBathrooms: body.maxBathrooms,
    radius: body.radius,
    furnishType,
    page: 1,
    pageSize: 25
  };

  // 1. Search for properties
  const results = await api.searchProperties(params);
  console.log(`Found ${results.properties.length} properties`);

  if (results.properties.length === 0) {
    return { properties: [], total: 0, saved: 0 };
  }

  // 2. Fetch HD details for top 10 properties
  const maxToProcess = Math.min(results.properties.length, 10);
  const propertiesWithDetails: PropertyWithDetails[] = [];

  console.log(`Fetching HD details for ${maxToProcess} properties...`);

  for (let i = 0; i < maxToProcess; i++) {
    const property = results.properties[i];
    try {
      const details = await api.getPropertyDetails(property.identifier);
      const p = details.property;

      // Combine list item data with HD details
      const propertyWithDetails: PropertyWithDetails = {
        ...property,
        bathrooms: parseInt(p.analyticsInfo?.bathrooms || '0', 10),
        hdImages: p.photos?.map(photo => photo.maxSizeUrl) || []
      };

      propertiesWithDetails.push(propertyWithDetails);
      console.log(`  ✓ ${i + 1}/${maxToProcess}: ${property.address.substring(0, 40)}...`);

      // Small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 100));
    } catch (error) {
      console.error(`  ✗ Failed to fetch details for ${property.identifier}:`, error);
      // Still include the property without HD details
      propertiesWithDetails.push({
        ...property,
        bathrooms: 0,
        hdImages: []
      });
    }
  }

  // 3. Save to Supabase and link to query
  console.log('Saving properties to database...');

  const query = { id: body.queryId } as any;
  const saveResult = await supabase.processPropertiesWithDetails(query, propertiesWithDetails);

  console.log(`Saved ${saveResult.newCount} properties to database`);

  if (saveResult.errors.length > 0) {
    console.log('Errors:', saveResult.errors);
  }

  // 4. Return properties in the format the app expects
  const responseProperties = propertiesWithDetails.map(p => ({
    id: String(p.identifier),
    images: p.hdImages && p.hdImages.length > 0
      ? p.hdImages.slice(0, 10)
      : p.thumbnailPhotos?.map(photo => photo.url) || [],
    price: p.displayPrices?.[0]?.displayPrice || `£${p.monthlyRent} pcm`,
    bedrooms: p.bedrooms || 0,
    bathrooms: p.bathrooms || 0,
    address: p.address,
    area: p.address.split(',').pop()?.trim() || '',
    rightmoveUrl: `https://www.rightmove.co.uk/properties/${p.identifier}`,
    agentPhone: p.branch?.contactTelephoneNumber || null,
    agentName: p.branch?.brandName || null,
    branchName: p.branch?.name || null,
    latitude: p.latitude || null,
    longitude: p.longitude || null
  }));

  return {
    properties: responseProperties,
    total: results.total,
    saved: saveResult.newCount
  };
}

async function handlePropertyDetails(propertyId: string) {
  const response = await api.getPropertyDetails(propertyId);
  const p = response.property;

  // Clean response - only send what the app needs
  return {
    id: p.identifier,
    bedrooms: p.bedrooms,
    bathrooms: parseInt(p.analyticsInfo?.bathrooms || '0', 10),
    address: p.address,
    price: p.displayPrices?.[0]?.displayPrice || `£${p.price} pcm`,
    description: p.fullDescription || p.summary,
    propertyType: p.propertySubtype || p.analyticsInfo?.propertySubType,
    furnishType: p.letFurnishType,
    availableFrom: p.letDateAvailable,
    latitude: p.latitude,
    longitude: p.longitude,
    photos: p.photos?.map((photo) => photo.maxSizeUrl) || [],
    floorplans: p.floorplans?.map((fp) => fp.url) || [],
    features: p.features?.map((f) => f.featureDescription) || [],
    stations: p.stations?.map((s) => ({ name: s.station, distance: s.distance })) || [],
    agent: {
      name: p.branch?.brandName,
      branch: p.branch?.name,
      phone: p.telephoneNumber,
      address: p.branch?.address
    }
  };
}

// ===========================================
// HTTP Server
// ===========================================

const server = http.createServer(async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // GET /api/property/:id/details - Fetch property details
  const detailsMatch = req.url?.match(/^\/api\/property\/(\d+)\/details$/);
  if (detailsMatch && req.method === 'GET') {
    const propertyId = detailsMatch[1];

    try {
      console.log(`\n--- Property Details Request ---`);
      console.log('Property ID:', propertyId);

      const cleanResponse = await handlePropertyDetails(propertyId);

      console.log('Bathrooms:', cleanResponse.bathrooms);
      console.log('Photos:', cleanResponse.photos.length);

      res.writeHead(200);
      res.end(JSON.stringify(cleanResponse));

    } catch (error) {
      console.error('Error fetching property details:', error);
      const message = error instanceof Error ? error.message : 'Unknown error';
      res.writeHead(500);
      res.end(JSON.stringify({ error: message }));
    }
    return;
  }

  // POST /api/search - Search for properties
  if (req.url === '/api/search' && req.method === 'POST') {
    let body = '';

    req.on('data', (chunk) => {
      body += chunk.toString();
    });

    req.on('end', async () => {
      try {
        const data = JSON.parse(body) as SearchRequest;

        if (data.latitude === undefined || data.longitude === undefined) {
          res.writeHead(400);
          res.end(JSON.stringify({ error: 'latitude and longitude are required' }));
          return;
        }

        console.log('\n--- Search Request ---');
        console.log('Location:', data.latitude, data.longitude);
        console.log('Price:', data.minPrice || 'any', '-', data.maxPrice || 'any');
        console.log('Beds:', data.minBedrooms || 'any', '-', data.maxBedrooms || 'any');
        console.log('Page:', data.page || 1);

        const result = await handleSearch(data);

        console.log('\n--- Response ---');
        console.log('Total:', result.total);
        console.log('Returned:', result.properties.length);
        console.log('Has more:', result.hasMore);

        res.writeHead(200);
        res.end(JSON.stringify(result));

      } catch (error) {
        console.error('Error:', error);
        const message = error instanceof Error ? error.message : 'Unknown error';
        res.writeHead(500);
        res.end(JSON.stringify({ error: message }));
      }
    });
    return;
  }

  // POST /api/onboarding-search - Search, fetch HD, save to Supabase
  if (req.url === '/api/onboarding-search' && req.method === 'POST') {
    let body = '';

    req.on('data', (chunk) => {
      body += chunk.toString();
    });

    req.on('end', async () => {
      try {
        const data = JSON.parse(body) as OnboardingSearchRequest;

        if (data.latitude === undefined || data.longitude === undefined) {
          res.writeHead(400);
          res.end(JSON.stringify({ error: 'latitude and longitude are required' }));
          return;
        }

        if (!data.queryId) {
          res.writeHead(400);
          res.end(JSON.stringify({ error: 'queryId is required' }));
          return;
        }

        const result = await handleOnboardingSearch(data);

        console.log('\n--- Onboarding Response ---');
        console.log('Total available:', result.total);
        console.log('Returned:', result.properties.length);
        console.log('Saved to DB:', result.saved);

        res.writeHead(200);
        res.end(JSON.stringify(result));

      } catch (error) {
        console.error('Error:', error);
        const message = error instanceof Error ? error.message : 'Unknown error';
        res.writeHead(500);
        res.end(JSON.stringify({ error: message }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Not found. Use POST /api/search, POST /api/onboarding-search, or GET /api/property/:id/details' }));
});

server.listen(PORT, () => {
  console.log(`\n🚀 Live Search API running at http://localhost:${PORT}`);
  console.log(`   Using Rightmove API`);
  console.log(`\nEndpoints:`);
  console.log(`  POST /api/search - Search properties`);
  console.log(`  POST /api/onboarding-search - Search, fetch HD images, save to DB`);
  console.log(`  GET  /api/property/:id/details - Get property details`);
  console.log(`\nPress Ctrl+C to stop\n`);
});
