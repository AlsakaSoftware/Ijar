/**
 * Rightmove API Client
 * Handles communication with Rightmove's mobile API
 */

import * as https from 'https';
import * as zlib from 'zlib';
import {
  PropertySearchParams,
  PropertySearchResult,
  PropertyListItem,
  PropertyDetails,
  PropertySearchAPIResponse,
  PropertyDetailsAPIResponse
} from '../types';

const API_BASE = 'api.rightmove.co.uk';

// Headers that mimic the official Rightmove iOS app
const API_HEADERS = {
  'Host': 'api.rightmove.co.uk',
  'Content-Type': 'application/json',
  'Accept': '*/*',
  'Cookie': 'permuserid=2506309L1QVROP2IYQO9XHPHA849PDWY',
  'User-Agent': 'Rightmove/8876 CFNetwork/3860.300.31 Darwin/25.2.0',
  'Accept-Language': 'en-GB,en;q=0.9',
  'Accept-Encoding': 'gzip, deflate, br',
  'Connection': 'keep-alive'
};

/**
 * Make an HTTPS request to the Rightmove API
 */
function makeRequest<T>(path: string): Promise<T> {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: API_BASE,
      port: 443,
      path,
      method: 'GET',
      headers: API_HEADERS
    };

    const req = https.request(options, (res) => {
      const chunks: Buffer[] = [];

      res.on('data', (chunk) => chunks.push(chunk));

      res.on('end', () => {
        const buffer = Buffer.concat(chunks);
        const encoding = res.headers['content-encoding'];

        let data: string;
        try {
          if (encoding === 'gzip') {
            data = zlib.gunzipSync(buffer).toString('utf-8');
          } else if (encoding === 'br') {
            data = zlib.brotliDecompressSync(buffer).toString('utf-8');
          } else if (encoding === 'deflate') {
            data = zlib.inflateSync(buffer).toString('utf-8');
          } else {
            data = buffer.toString('utf-8');
          }

          const json = JSON.parse(data);

          if (res.statusCode !== 200) {
            reject(new Error(`API error: ${res.statusCode} - ${json.title || json.detail || 'Unknown error'}`));
            return;
          }

          resolve(json as T);
        } catch (e) {
          reject(new Error(`Failed to parse response: ${e}`));
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

/**
 * Create LAT_LONG_BOX location identifier from coordinates
 * Format: LAT_LONG_BOX^westLong,eastLong,southLat,northLat
 */
function createLocationBox(lat: number, lng: number): string {
  const delta = 0.0005; // ~50m bounding box
  const westLong = lng - delta;
  const eastLong = lng + delta;
  const southLat = lat - delta;
  const northLat = lat + delta;
  return `LAT_LONG_BOX^${westLong},${eastLong},${southLat},${northLat}`;
}

/**
 * Rightmove API Client
 */
export class RightmoveAPI {
  /**
   * Search for rental properties
   */
  async searchProperties(params: PropertySearchParams): Promise<PropertySearchResult> {
    const locationId = createLocationBox(params.latitude, params.longitude);

    const queryParams = new URLSearchParams({
      channel: 'RENT',
      locationIdentifier: locationId,
      page: String(params.page || 1),
      appVersion: '10.31',
      numberOfPropertiesPerPage: String(params.pageSize || 25),
      sortBy: params.sortBy || 'newestListed',
      includeUnavailableProperties: 'false',
      apiApplication: 'IPHONE',
      radius: String(params.radius ?? 1)
    });

    // Only add optional params if they have values (not null/undefined)
    if (params.minPrice != null) {
      queryParams.set('minPrice', String(params.minPrice));
    }
    if (params.maxPrice != null) {
      queryParams.set('maxPrice', String(params.maxPrice));
    }
    if (params.minBedrooms != null) {
      queryParams.set('minBedrooms', String(params.minBedrooms));
    }
    if (params.maxBedrooms != null) {
      queryParams.set('maxBedrooms', String(params.maxBedrooms));
    }
    if (params.minBathrooms != null) {
      queryParams.set('minBathrooms', String(params.minBathrooms));
    }
    if (params.maxBathrooms != null) {
      queryParams.set('maxBathrooms', String(params.maxBathrooms));
    }
    if (params.furnishType) {
      queryParams.set('furnishTypes', params.furnishType);
    }
    if (params.propertyTypes && params.propertyTypes.length > 0) {
      queryParams.set('propertyTypes', params.propertyTypes.join(','));
    }

    const path = `/api/property-listing?${queryParams.toString()}`;
    console.log('API Request:', path);

    const response = await makeRequest<PropertySearchAPIResponse>(path);

    const page = params.page || 1;
    const pageSize = params.pageSize || 25;
    const hasMore = page * pageSize < response.totalAvailableResults;

    return {
      properties: response.properties,
      total: response.totalAvailableResults,
      page,
      hasMore
    };
  }

  /**
   * Get detailed information for a specific property
   * Includes HD images, bathrooms, full description, etc.
   */
  async getPropertyDetails(propertyId: string | number): Promise<PropertyDetailsAPIResponse> {
    const path = `/api/property/${propertyId}?appVersion=10.31&apiApplication=IPHONE`;
    return makeRequest<PropertyDetailsAPIResponse>(path);
  }
}
