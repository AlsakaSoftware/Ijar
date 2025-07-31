import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { RightmoveProperty, RightmoveStation } from './scraper-types';

// Database types - core data only
export interface DatabaseProperty {
  id?: string;
  rightmove_id: number;
  images: string[];
  price: string;
  bedrooms: number;
  bathrooms: number;
  address: string;
  area?: string;
  search?: string;
  created?: string;
  updated?: string;
  active?: boolean;
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
  private mapRightmoveToDatabase(property: RightmoveProperty, searchName?: string): DatabaseProperty {
    // Extract area from address (postcode or area after last comma)
    const addressParts = property.displayAddress.split(',');
    const area = addressParts.length > 1 ? addressParts[addressParts.length - 1].trim() : undefined;

    return {
      rightmove_id: property.id,
      images: property.images.map(img => img.srcUrl || img.url),
      price: property.price?.displayPrices?.[0]?.displayPrice || 'Price on request',
      bedrooms: property.bedrooms || 0,
      bathrooms: property.bathrooms || 0,
      address: property.displayAddress,
      area,
      search: searchName,
      active: true
    };
  }

  // Insert a new property (with upsert to handle duplicates)
  async upsertProperty(property: RightmoveProperty, searchName?: string): Promise<{ success: boolean; property?: DatabaseProperty; error?: string }> {
    try {
      const dbProperty = this.mapRightmoveToDatabase(property, searchName);
      
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
  async upsertProperties(properties: RightmoveProperty[], searchName?: string): Promise<{ success: boolean; count: number; errors: string[] }> {
    const errors: string[] = [];
    let successCount = 0;

    for (const property of properties) {
      const result = await this.upsertProperty(property, searchName);
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

  // Get properties by search name
  async getPropertiesBySearch(searchName: string, limit = 50): Promise<DatabaseProperty[]> {
    try {
      const { data, error } = await this.supabase
        .from('property')
        .select('*')
        .eq('search', searchName)
        .eq('active', true)
        .order('created', { ascending: false })
        .limit(limit);

      if (error) {
        console.error('Error fetching properties:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Exception fetching properties:', error);
      return [];
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

  // Mark properties as inactive (instead of deleting)
  async deactivateOldProperties(searchName: string, keepDays = 30): Promise<number> {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - keepDays);

      const { data, error } = await this.supabase
        .from('property')
        .update({ active: false })
        .eq('search', searchName)
        .lt('updated', cutoffDate.toISOString())
        .eq('active', true)
        .select('id');

      if (error) {
        console.error('Error deactivating old properties:', error);
        return 0;
      }

      return data?.length || 0;
    } catch (error) {
      console.error('Exception deactivating old properties:', error);
      return 0;
    }
  }
}