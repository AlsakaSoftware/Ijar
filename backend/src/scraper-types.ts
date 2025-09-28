export interface SearchOptions {
  searchType?: 'SALE' | 'RENT';
  postcode: string;
  minPrice?: number;
  maxPrice?: number;
  minBedrooms?: number;
  maxBedrooms?: number;
  minBathrooms?: number;
  maxBathrooms?: number;
  furnishTypes?: 'furnished' | 'unfurnished' | 'furnished_or_unfurnished';
  radius?: number;
  propertyTypes?: string;
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

export interface RightmoveStation {
  name: string;
  types: string[]; // e.g., ["LONDON_UNDERGROUND", "LIGHT_RAILWAY"]
  distance: number;
  unit: string; // "miles"
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
  customer?: {
    branchId: number;
    brandPlusLogoURI: string;
    contactTelephone: string;
    branchDisplayName: string;
    branchName: string;
    brandTradingName: string;
    branchLandingPageUrl: string;
    mediaServerUrl: string;
    hasBrandPlus: boolean;
    brandPlusLogoUrl?: string;
    primaryBrandColour?: string;
  };
  nearbyStations?: RightmoveStation[];
  transportDescription?: string;
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