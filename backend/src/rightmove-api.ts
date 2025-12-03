import * as https from 'https';
import * as zlib from 'zlib';

const API_BASE = 'api.rightmove.co.uk';
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

// API response types
export interface RightmoveAPIProperty {
  identifier: number;
  bedrooms: number;
  address: string;
  propertyType: string;
  status: string | null;
  transactionTypeId: number;
  photoCount: number;
  floorplanCount: number;
  price: number;
  monthlyRent: number;
  priceQualifier: string;
  photoThumbnailUrl: string;
  photoLargeThumbnailUrl: string;
  displayPrices: Array<{
    displayPrice: string;
    displayPriceQualifier: string;
  }>;
  thumbnailPhotos: Array<{ url: string }>;
  summary: string;
  latitude: number;
  longitude: number;
  branch: {
    identifier: number;
    branchLogo: string;
    brandName: string;
    name: string;
    contactTelephoneNumber: string;
  };
  listingUpdateReason: string;
  development: boolean;
  buildToRent: boolean;
}

export interface RightmoveAPISearchResponse {
  properties: RightmoveAPIProperty[];
  featuredProperties: RightmoveAPIProperty[];
  totalAvailableResults: number;
  numReturnedResults: number;
  radius: number;
  channel: string;
  locationInfo: {
    locationIdentifier: string;
    name: string;
    centreLatitude: number;
    centreLongitude: number;
  };
}

export interface RightmoveAPIPropertyDetails {
  property: {
    identifier: number;
    bedrooms: number;
    address: string;
    summary: string;
    fullDescription: string;
    propertySubtype: string;
    price: number;
    latitude: number;
    longitude: number;
    letFurnishType: string;
    letType: string;
    letDateAvailable: string;
    letBond: number;
    telephoneNumber: string;
    publicsiteUrl: string;
    branch: {
      identifier: number;
      name: string;
      brandName: string;
      branchLogo: string;
      address: string;
    };
    displayPrices: Array<{
      displayPrice: string;
      displayPriceQualifier: string;
    }>;
    stations: Array<{
      station: string;
      distance: number;
      type: string;
    }>;
    features: Array<{
      featureDescription: string;
    }>;
    photos: Array<{
      url: string;
      thumbnailUrl: string;
      maxSizeUrl: string;
      caption: string | null;
      order: number;
    }>;
    floorplans: Array<{
      url: string;
      caption: string | null;
    }>;
    virtualTours: Array<{
      url: string;
      caption: string | null;
    }>;
    analyticsInfo: {
      bathrooms: string;
      propertyType: string;
      propertySubType: string;
    };
    lettingsInfo: {
      content: Array<{
        type: string;
        title: string;
        value: string;
      }>;
    };
    propertyDetailsInfo: {
      content: Array<{
        type: string;
        title: string;
        value: string;
      }>;
    };
  };
}

export interface SearchParams {
  latitude: number;
  longitude: number;
  minPrice?: number;
  maxPrice?: number;
  minBedrooms?: number;
  maxBedrooms?: number;
  minBathrooms?: number;
  maxBathrooms?: number;
  radius?: number;
  furnishType?: 'furnished' | 'unfurnished';
  propertyTypes?: string[];
  page?: number;
  pageSize?: number;
  sortBy?: 'newestListed' | 'highestPrice' | 'lowestPrice' | 'oldestListed';
}

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

// Create LAT_LONG_BOX from coordinates
// Format: LAT_LONG_BOX^westLong,eastLong,southLat,northLat
function createLocationBox(lat: number, lng: number): string {
  // Create a small bounding box around the point (roughly ~50m)
  const delta = 0.0005;
  const westLong = lng - delta;
  const eastLong = lng + delta;
  const southLat = lat - delta;
  const northLat = lat + delta;
  return `LAT_LONG_BOX^${westLong},${eastLong},${southLat},${northLat}`;
}

export class RightmoveAPI {
  async searchProperties(params: SearchParams): Promise<{
    properties: RightmoveAPIProperty[];
    total: number;
    page: number;
    hasMore: boolean;
  }> {
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
    if (params.minPrice !== undefined) {
      queryParams.set('minPrice', String(params.minPrice));
    }
    if (params.maxPrice !== undefined) {
      queryParams.set('maxPrice', String(params.maxPrice));
    }
    if (params.minBedrooms !== undefined) {
      queryParams.set('minBedrooms', String(params.minBedrooms));
    }
    if (params.maxBedrooms !== undefined) {
      queryParams.set('maxBedrooms', String(params.maxBedrooms));
    }
    if (params.minBathrooms !== undefined) {
      queryParams.set('minBathrooms', String(params.minBathrooms));
    }
    if (params.maxBathrooms !== undefined) {
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

    const response = await makeRequest<RightmoveAPISearchResponse>(path);

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

  async getPropertyDetails(propertyId: string | number): Promise<RightmoveAPIPropertyDetails> {
    const path = `/api/property/${propertyId}?appVersion=10.31&apiApplication=IPHONE`;
    return makeRequest<RightmoveAPIPropertyDetails>(path);
  }
}
