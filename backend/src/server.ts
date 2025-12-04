/**
 * Live Search API Server
 * HTTP server for property search and details endpoints
 */

import * as http from 'http';
import { RightmoveAPI } from './api';
import { PropertySearchParams } from './types';

const PORT = process.env.PORT || 3001;

const api = new RightmoveAPI();

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

  } else {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found. Use POST /api/search or GET /api/property/:id/details' }));
  }
});

server.listen(PORT, () => {
  console.log(`\n🚀 Live Search API running at http://localhost:${PORT}`);
  console.log(`   Using Rightmove API`);
  console.log(`\nEndpoints:`);
  console.log(`  POST /api/search - Search properties`);
  console.log(`  GET  /api/property/:id/details - Get property details`);
  console.log(`\nPress Ctrl+C to stop\n`);
});
