/**
 * Database Types
 * Types for Supabase database tables
 */

// ===========================================
// Property Table
// ===========================================

export interface DbProperty {
  id?: string;
  rightmove_id: number;
  images: string[];
  price: string;
  bedrooms: number;
  bathrooms: number;
  address: string;
  area?: string;
  rightmove_url?: string;
  agent_phone?: string;
  agent_name?: string;
  branch_name?: string;
  latitude?: number;
  longitude?: number;
  created?: string;
  updated?: string;
}

// ===========================================
// Query Table (Saved Searches)
// ===========================================

export interface DbQuery {
  id?: string;
  user_id?: string;
  name: string;
  area_name: string;
  latitude: number;
  longitude: number;
  min_price?: number;
  max_price?: number;
  min_bedrooms?: number;
  max_bedrooms?: number;
  min_bathrooms?: number;
  max_bathrooms?: number;
  radius?: number;
  furnish_type?: string;
  active?: boolean;
  created?: string;
  updated?: string;
}

// ===========================================
// Query-Property Junction Table
// ===========================================

export interface DbQueryProperty {
  id?: string;
  query_id: string;
  property_id: string;
  found_at?: string;
  score?: number;
}

// ===========================================
// Device Token Table (for Push Notifications)
// ===========================================

export interface DbDeviceToken {
  id?: string;
  user_id: string;
  token: string;
  platform: 'ios' | 'android';
  created?: string;
  updated?: string;
}
