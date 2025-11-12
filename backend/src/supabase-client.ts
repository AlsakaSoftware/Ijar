import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { RightmoveProperty } from './scraper-types';

// Database types for new schema
export interface DatabaseProperty {
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

export interface UserQuery {
  id?: string;
  user_id?: string;
  name: string;
  postcode: string;
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

export interface QueryProperty {
  id?: string;
  query_id: string;
  property_id: string;
  found_at?: string;
  score?: number;
}

export class SupabasePropertyClient {
  private supabase: SupabaseClient;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Use service role for backend operations

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables are required');
    }

    this.supabase = createClient(supabaseUrl, supabaseKey);
  }

  // Convert RightmoveProperty to DatabaseProperty
  private mapRightmoveToDatabase(property: RightmoveProperty): DatabaseProperty {
    // Extract area from address (postcode or area after last comma)
    const addressParts = property.displayAddress.split(',');
    const area = addressParts.length > 1 ? addressParts[addressParts.length - 1].trim() : undefined;

    return {
      rightmove_id: property.id,
      images: property.images.map(img => img.srcUrl || img.url), // Now contains HD URLs
      price: property.price?.displayPrices?.[0]?.displayPrice || 'Price on request',
      bedrooms: property.bedrooms || 0,
      bathrooms: property.bathrooms || 0,
      address: property.displayAddress,
      area,
      rightmove_url: property.propertyUrl ? `https://www.rightmove.co.uk${property.propertyUrl}` : undefined,
      agent_phone: property.customer?.contactTelephone || undefined,
      agent_name: property.customer?.brandTradingName || undefined,
      branch_name: property.customer?.branchDisplayName || undefined,
      latitude: property.location?.latitude || undefined,
      longitude: property.location?.longitude || undefined
    };
  }


  // Insert a new property (with upsert to handle duplicates)
  async upsertProperty(property: RightmoveProperty): Promise<{ success: boolean; property?: DatabaseProperty; error?: string }> {
    try {
      const dbProperty = this.mapRightmoveToDatabase(property);
      
      const { data, error } = await this.supabase
        .from('property')
        .upsert(dbProperty, { 
          onConflict: 'rightmove_id',
          ignoreDuplicates: false 
        })
        .select()
        .single();

      if (error) {
        console.error('Error upserting property:', error);
        return { success: false, error: error.message };
      }

      return { success: true, property: data };
    } catch (error) {
      console.error('Exception upserting property:', error);
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  // Insert multiple properties
  async upsertProperties(properties: RightmoveProperty[]): Promise<{ success: boolean; count: number; errors: string[] }> {
    const errors: string[] = [];
    let successCount = 0;

    for (const property of properties) {
      const result = await this.upsertProperty(property);
      if (result.success) {
        successCount++;
      } else {
        errors.push(`Property ${property.id}: ${result.error}`);
      }
    }

    return {
      success: errors.length === 0,
      count: successCount,
      errors
    };
  }

  // Check if property is already linked to query
  async isPropertyLinkedToQuery(queryId: string, rightmoveId: number): Promise<boolean> {
    try {
      const { data, error } = await this.supabase
        .from('query_property')
        .select('id')
        .eq('query_id', queryId)
        .eq('property_id', await this.getPropertyIdByRightmoveId(rightmoveId))
        .single();

      return !error && data !== null;
    } catch (error) {
      return false;
    }
  }

  // Get property ID by Rightmove ID
  async getPropertyIdByRightmoveId(rightmoveId: number): Promise<string | null> {
    try {
      const { data, error } = await this.supabase
        .from('property')
        .select('id')
        .eq('rightmove_id', rightmoveId)
        .single();

      return !error && data ? data.id : null;
    } catch (error) {
      return null;
    }
  }

  // Link property to query (without score for now)
  async linkPropertyToQuery(queryId: string, propertyId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await this.supabase
        .from('query_property')
        .upsert({
          query_id: queryId,
          property_id: propertyId
          // No score column in simplified schema
        }, {
          onConflict: 'query_id,property_id',
          ignoreDuplicates: true
        });

      if (error) {
        console.error('Error linking property to query:', error);
        return { success: false, error: error.message };
      }

      return { success: true };
    } catch (error) {
      console.error('Exception linking property to query:', error);
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  // Check if property exists by Rightmove ID
  async propertyExists(rightmoveId: number): Promise<boolean> {
    try {
      const { data, error } = await this.supabase
        .from('property')
        .select('id')
        .eq('rightmove_id', rightmoveId)
        .single();

      return !error && data !== null;
    } catch (error) {
      return false;
    }
  }

  // Get new properties (not in database)
  async getNewProperties(properties: RightmoveProperty[]): Promise<RightmoveProperty[]> {
    const newProperties: RightmoveProperty[] = [];

    for (const property of properties) {
      const exists = await this.propertyExists(property.id);
      if (!exists) {
        newProperties.push(property);
      }
    }

    return newProperties;
  }

  // Get properties that are new for a specific query (not yet linked)
  async getNewPropertiesForQuery(query: UserQuery, properties: RightmoveProperty[]): Promise<RightmoveProperty[]> {
    const newProperties: RightmoveProperty[] = [];

    for (const property of properties) {
      const isAlreadyLinked = await this.isPropertyLinkedToQuery(query.id!, property.id);
      if (!isAlreadyLinked) {
        newProperties.push(property);
      }
    }

    return newProperties;
  }

  // Get active user queries
  async getActiveQueries(): Promise<UserQuery[]> {
    try {
      const { data, error } = await this.supabase
        .from('query')
        .select('*')
        .eq('active', true)
        .order('created', { ascending: false });

      if (error) {
        console.error('Error fetching queries:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Exception fetching queries:', error);
      return [];
    }
  }

  // Process properties for a specific query (properties are already filtered for new ones)
  async processPropertiesForQuery(query: UserQuery, properties: RightmoveProperty[]): Promise<{ success: boolean; newCount: number; errors: string[] }> {
    const errors: string[] = [];
    let newCount = 0;

    if (properties.length === 0) {
      return { success: true, newCount: 0, errors: [] };
    }

    console.log(`    💾 Saving ${properties.length} new properties to database...`);

    for (const property of properties) {
      try {
        // Upsert the property to the database
        const propertyResult = await this.upsertProperty(property);
        if (!propertyResult.success) {
          errors.push(`Failed to save property ${property.id}: ${propertyResult.error}`);
          continue;
        }

        // Link it to the query
        const linkResult = await this.linkPropertyToQuery(query.id!, propertyResult.property!.id!);
        if (linkResult.success) {
          newCount++;
          console.log(`    ✅ Saved property ${property.id} (${property.displayAddress})`);
        } else {
          errors.push(`Failed to link property ${property.id} to query: ${linkResult.error}`);
        }
      } catch (error) {
        errors.push(`Exception processing property ${property.id}: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    return {
      success: errors.length === 0,
      newCount,
      errors
    };
  }
}