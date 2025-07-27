export interface LocationConfig {
  id: string;
  name: string;
  params: string;
}

export interface SearchOptions {
  searchType?: 'SALE' | 'RENT';
  locationIdentifier?: string;
  location?: string;
  minPrice?: number;
  maxPrice?: number;
  minBedrooms?: number;
  maxBedrooms?: number;
  furnishTypes?: 'furnished' | 'unfurnished' | 'furnished_or_unfurnished';
  getAllPages?: boolean;
  quiet?: boolean;
}

export interface RightmoveImage {
  srcUrl: string;
  url: string;
  caption: string;
}

export interface RightmovePrice {
  displayPrice: string;
  displayPriceQualifier?: string;
}

export interface RightmoveProperty {
  id: number;
  bedrooms: number;
  bathrooms: number;
  numberOfImages: number;
  numberOfFloorplans: number;
  numberOfVirtualTours: number;
  summary: string;
  displayAddress: string;
  countryCode: string;
  location: {
    latitude: number;
    longitude: number;
  };
  images: RightmoveImage[];
  price: {
    displayPrices: RightmovePrice[];
    displayPrice?: string;
  };
  propertyUrl: string;
  contactUrl: string;
  staticMapUrl?: string;
  channel?: string;
  firstVisibleDate?: string;
  keywords?: string[];
  keywordMatchType?: string;
  addedOrReduced?: string;
  isRecent?: boolean;
  propertyTypeFullDescription?: string;
  propertySubType?: string;
  displaySize?: string;
  displayStatus?: string;
  letType?: string;
  letAvailableDate?: string;
  hasBrandPlus?: boolean;
  brand?: {
    brandTradingName: string;
    contactTelephone: string;
    branchDisplayName: string;
  };
  agent?: {
    phone: string;
    name: string;
    branchName: string;
  };
}

export interface SearchResults {
  properties: RightmoveProperty[];
  total: number;
  pages: number;
}

export interface ApiResponse {
  statusCode: number;
  data: string;
  headers: Record<string, string>;
}

export interface NextDataPageProps {
  searchResults?: {
    properties: RightmoveProperty[];
    pagination?: {
      total: number;
      pageNumber: number;
      pageSize: number;
    };
  };
}

export interface NextData {
  props?: {
    pageProps?: NextDataPageProps;
  };
}