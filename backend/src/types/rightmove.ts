/**
 * Rightmove API Types
 * Types for the Rightmove mobile API responses
 */

// ===========================================
// Property Search Types (from /api/property-listing)
// ===========================================

export interface PropertySearchParams {
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

export interface PropertySearchResult {
  properties: PropertyListItem[];
  total: number;
  page: number;
  hasMore: boolean;
}

/** Property item from search results (minimal data) */
export interface PropertyListItem {
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
  displayPrices: DisplayPrice[];
  thumbnailPhotos: ThumbnailPhoto[];
  summary: string;
  latitude: number;
  longitude: number;
  branch: BranchInfo;
  listingUpdateReason: string;
  development: boolean;
  buildToRent: boolean;
}

export interface DisplayPrice {
  displayPrice: string;
  displayPriceQualifier: string;
}

export interface ThumbnailPhoto {
  url: string;
}

export interface BranchInfo {
  identifier: number;
  branchLogo: string;
  brandName: string;
  name: string;
  contactTelephoneNumber: string;
}

// Raw API response shape
export interface PropertySearchAPIResponse {
  properties: PropertyListItem[];
  featuredProperties: PropertyListItem[];
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

// ===========================================
// Property Details Types (from /api/property/:id)
// ===========================================

export interface PropertyDetailsAPIResponse {
  property: PropertyDetails;
}

/** Full property details (comprehensive data) */
export interface PropertyDetails {
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
  displayPrices: DisplayPrice[];
  stations: Station[];
  features: Feature[];
  photos: Photo[];
  floorplans: Floorplan[];
  virtualTours: VirtualTour[];
  analyticsInfo: AnalyticsInfo;
  lettingsInfo: ContentSection;
  propertyDetailsInfo: ContentSection;
}

export interface Station {
  station: string;
  distance: number;
  type: string;
}

export interface Feature {
  featureDescription: string;
}

export interface Photo {
  url: string;
  thumbnailUrl: string;
  maxSizeUrl: string;
  caption: string | null;
  order: number;
}

export interface Floorplan {
  url: string;
  caption: string | null;
}

export interface VirtualTour {
  url: string;
  caption: string | null;
}

export interface AnalyticsInfo {
  bathrooms: string;
  propertyType: string;
  propertySubType: string;
}

export interface ContentSection {
  content: ContentItem[];
}

export interface ContentItem {
  type: string;
  title: string;
  value: string;
}

// ===========================================
// Extended Types (with fetched details)
// ===========================================

/** Property with HD images and bathrooms from details API */
export interface PropertyWithDetails extends PropertyListItem {
  hdImages?: string[];
  bathrooms?: number;
}
