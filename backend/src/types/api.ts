/**
 * API Types
 * Request/Response types for all API endpoints
 */

// =============================================================================
// Shared Types
// =============================================================================

/** Property data as sent from iOS (snake_case) */
export interface Property {
  id: string;
  images: string[];
  price: string;
  bedrooms: number;
  bathrooms: number;
  address: string;
  area?: string | null;
  rightmove_url?: string | null;
  agent_phone?: string | null;
  agent_name?: string | null;
  branch_name?: string | null;
  latitude?: number | null;
  longitude?: number | null;
}

/** Property group */
export interface PropertyGroup {
  id: string;
  user_id: string;
  name: string;
  created_at: string;
  property_count: number;
}

// =============================================================================
// Request Types
// =============================================================================

// Properties
export interface SavePropertyRequest {
  userId: string;
  property: Property;
}

export interface UnsavePropertyRequest {
  userId: string;
  propertyId: string;
}

// Groups
export interface CreateGroupRequest {
  userId: string;
  name: string;
}

export interface RenameGroupRequest {
  name: string;
}

export interface AddPropertyToGroupRequest {
  propertyId: string;
}

// Search
export interface SearchRequest {
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

export interface OnboardingSearchRequest extends SearchRequest {
  queryId: string;
}

// =============================================================================
// Response Types
// =============================================================================

/** Standard success response */
export interface SuccessResponse {
  success: true;
}

/** Save property response */
export interface SavePropertyResponse {
  success: boolean;
  property_id?: string;
}

/** Create group response */
export interface CreateGroupResponse {
  group: PropertyGroup;
}

/** Search response */
export interface SearchResponse {
  properties: Property[];
  total: number;
  hasMore: boolean;
  page: number;
}

/** Onboarding search response */
export interface OnboardingSearchResponse {
  properties: Property[];
  total: number;
  saved: number;
}
