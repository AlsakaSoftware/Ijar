/**
 * Search Routes
 * Handles property search and details endpoints
 */

import { Router } from './index';
import { RightmoveAPI } from '../api';
import { SupabaseService } from '../services/supabase';
import { PropertySearchParams, PropertyWithDetails } from '../types';
import { parseJsonBody, sendJson, sendError } from '../utils/http';

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
  queryId: string;
}

export function registerSearchRoutes(router: Router, api: RightmoveAPI, supabase: SupabaseService): void {

  // POST /api/search - Search for properties
  router.post('/api/search', async (req, res) => {
    try {
      const body = await parseJsonBody<SearchRequest>(req);

      if (body.latitude === undefined || body.longitude === undefined) {
        sendError(res, 'latitude and longitude are required', 400);
        return;
      }

      console.log('\n--- Search Request ---');
      console.log('Location:', body.latitude, body.longitude);
      console.log('Price:', body.minPrice || 'any', '-', body.maxPrice || 'any');
      console.log('Beds:', body.minBedrooms || 'any', '-', body.maxBedrooms || 'any');
      console.log('Page:', body.page || 1);

      const result = await handleSearch(api, body);

      console.log('\n--- Response ---');
      console.log('Total:', result.total);
      console.log('Returned:', result.properties.length);
      console.log('Has more:', result.hasMore);

      sendJson(res, result);
    } catch (error) {
      console.error('Error:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // POST /api/onboarding-search - Search, fetch HD, save to Supabase
  router.post('/api/onboarding-search', async (req, res) => {
    try {
      const body = await parseJsonBody<OnboardingSearchRequest>(req);

      if (body.latitude === undefined || body.longitude === undefined) {
        sendError(res, 'latitude and longitude are required', 400);
        return;
      }

      if (!body.queryId) {
        sendError(res, 'queryId is required', 400);
        return;
      }

      const result = await handleOnboardingSearch(api, supabase, body);

      console.log('\n--- Onboarding Response ---');
      console.log('Total available:', result.total);
      console.log('Returned:', result.properties.length);
      console.log('Saved to DB:', result.saved);

      sendJson(res, result);
    } catch (error) {
      console.error('Error:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });

  // GET /api/property/:id/details - Fetch property details
  router.get('/api/property/:id/details', async (req, res, params) => {
    try {
      console.log(`\n--- Property Details Request ---`);
      console.log('Property ID:', params.id);

      const cleanResponse = await handlePropertyDetails(api, params.id);

      console.log('Bathrooms:', cleanResponse.bathrooms);
      console.log('Photos:', cleanResponse.photos.length);

      sendJson(res, cleanResponse);
    } catch (error) {
      console.error('Error fetching property details:', error);
      sendError(res, error instanceof Error ? error.message : 'Unknown error');
    }
  });
}

async function handleSearch(api: RightmoveAPI, body: SearchRequest) {
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

async function handleOnboardingSearch(api: RightmoveAPI, supabase: SupabaseService, body: OnboardingSearchRequest) {
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

      const propertyWithDetails: PropertyWithDetails = {
        ...property,
        bathrooms: parseInt(p.analyticsInfo?.bathrooms || '0', 10),
        hdImages: p.photos?.map(photo => photo.maxSizeUrl) || []
      };

      propertiesWithDetails.push(propertyWithDetails);
      console.log(`  ✓ ${i + 1}/${maxToProcess}: ${property.address.substring(0, 40)}...`);

      await new Promise(resolve => setTimeout(resolve, 100));
    } catch (error) {
      console.error(`  ✗ Failed to fetch details for ${property.identifier}:`, error);
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

  // 4. Return properties in snake_case format
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
    rightmove_url: `https://www.rightmove.co.uk/properties/${p.identifier}`,
    agent_phone: p.branch?.contactTelephoneNumber || null,
    agent_name: p.branch?.brandName || null,
    branch_name: p.branch?.name || null,
    latitude: p.latitude || null,
    longitude: p.longitude || null
  }));

  return {
    properties: responseProperties,
    total: results.total,
    saved: saveResult.newCount
  };
}

async function handlePropertyDetails(api: RightmoveAPI, propertyId: string) {
  const response = await api.getPropertyDetails(propertyId);
  const p = response.property;

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
