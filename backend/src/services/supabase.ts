/**
 * Supabase Service
 * Handles all database operations
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { DbProperty, DbQuery, PropertyListItem, PropertyWithDetails } from '../types';

export class SupabaseService {
  private client: SupabaseClient;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables are required');
    }

    this.client = createClient(supabaseUrl, supabaseKey);
  }

  // ===========================================
  // Property Operations
  // ===========================================

  /**
   * Convert API property (list item) to database format
   */
  private mapListItemToDb(property: PropertyListItem): DbProperty {
    const addressParts = property.address.split(',');
    const area = addressParts.length > 1 ? addressParts[addressParts.length - 1].trim() : undefined;

    return {
      rightmove_id: property.identifier,
      images: property.thumbnailPhotos?.map(p => p.url) || [],
      price: property.displayPrices?.[0]?.displayPrice || `£${property.monthlyRent} pcm`,
      bedrooms: property.bedrooms || 0,
      bathrooms: 0,
      address: property.address,
      area,
      rightmove_url: `https://www.rightmove.co.uk/properties/${property.identifier}`,
      agent_phone: property.branch?.contactTelephoneNumber || undefined,
      agent_name: property.branch?.brandName || undefined,
      branch_name: property.branch?.name || undefined,
      latitude: property.latitude || undefined,
      longitude: property.longitude || undefined
    };
  }

  /**
   * Convert API property with details to database format
   */
  private mapPropertyToDb(property: PropertyWithDetails): DbProperty {
    const addressParts = property.address.split(',');
    const area = addressParts.length > 1 ? addressParts[addressParts.length - 1].trim() : undefined;

    // Use HD images if available, otherwise fall back to thumbnails
    // Limit to 10 images to reduce storage/bandwidth
    const allImages = property.hdImages && property.hdImages.length > 0
      ? property.hdImages
      : property.thumbnailPhotos?.map(p => p.url) || [];
    const images = allImages.slice(0, 10);

    return {
      rightmove_id: property.identifier,
      images,
      price: property.displayPrices?.[0]?.displayPrice || `£${property.monthlyRent} pcm`,
      bedrooms: property.bedrooms || 0,
      bathrooms: property.bathrooms || 0,
      address: property.address,
      area,
      rightmove_url: `https://www.rightmove.co.uk/properties/${property.identifier}`,
      agent_phone: property.branch?.contactTelephoneNumber || undefined,
      agent_name: property.branch?.brandName || undefined,
      branch_name: property.branch?.name || undefined,
      latitude: property.latitude || undefined,
      longitude: property.longitude || undefined
    };
  }

  /**
   * Upsert a property (insert or update if exists)
   */
  async upsertProperty(property: PropertyWithDetails): Promise<{ success: boolean; property?: DbProperty; error?: string }> {
    try {
      const dbProperty = this.mapPropertyToDb(property);

      const { data, error } = await this.client
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

  /**
   * Check if a property exists by Rightmove ID
   */
  async propertyExists(rightmoveId: number): Promise<boolean> {
    try {
      const { data, error } = await this.client
        .from('property')
        .select('id')
        .eq('rightmove_id', rightmoveId)
        .single();

      return !error && data !== null;
    } catch {
      return false;
    }
  }

  /**
   * Get property ID by Rightmove ID
   */
  async getPropertyIdByRightmoveId(rightmoveId: number): Promise<string | null> {
    try {
      const { data, error } = await this.client
        .from('property')
        .select('id')
        .eq('rightmove_id', rightmoveId)
        .single();

      return !error && data ? data.id : null;
    } catch {
      return null;
    }
  }

  // ===========================================
  // Query (Saved Search) Operations
  // ===========================================

  /**
   * Get all active saved searches
   */
  async getActiveQueries(): Promise<DbQuery[]> {
    try {
      const { data, error } = await this.client
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

  // ===========================================
  // Query-Property Link Operations
  // ===========================================

  /**
   * Check if property is already linked to a query
   */
  async isPropertyLinkedToQuery(queryId: string, rightmoveId: number): Promise<boolean> {
    try {
      const propertyId = await this.getPropertyIdByRightmoveId(rightmoveId);
      if (!propertyId) return false;

      const { data, error } = await this.client
        .from('query_property')
        .select('id')
        .eq('query_id', queryId)
        .eq('property_id', propertyId)
        .single();

      return !error && data !== null;
    } catch {
      return false;
    }
  }

  /**
   * Link a property to a query
   */
  async linkPropertyToQuery(queryId: string, propertyId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const { error } = await this.client
        .from('query_property')
        .upsert({
          query_id: queryId,
          property_id: propertyId
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

  /**
   * Filter properties to only include new ones for a query
   */
  async getNewPropertiesForQuery(query: DbQuery, properties: PropertyListItem[]): Promise<PropertyListItem[]> {
    const newProperties: PropertyListItem[] = [];

    for (const property of properties) {
      const isAlreadyLinked = await this.isPropertyLinkedToQuery(query.id!, property.identifier);
      if (!isAlreadyLinked) {
        newProperties.push(property);
      }
    }

    return newProperties;
  }

  /**
   * Process properties with details for a query (with HD images and bathrooms)
   */
  async processPropertiesWithDetails(
    query: DbQuery,
    properties: PropertyWithDetails[]
  ): Promise<{ success: boolean; newCount: number; errors: string[] }> {
    const errors: string[] = [];
    let newCount = 0;

    if (properties.length === 0) {
      return { success: true, newCount: 0, errors: [] };
    }

    console.log(`    💾 Saving ${properties.length} new properties to database...`);

    for (const property of properties) {
      try {
        const propertyResult = await this.upsertProperty(property);
        if (!propertyResult.success) {
          errors.push(`Failed to save property ${property.identifier}: ${propertyResult.error}`);
          continue;
        }

        const linkResult = await this.linkPropertyToQuery(query.id!, propertyResult.property!.id!);
        if (linkResult.success) {
          newCount++;
          console.log(`    ✅ Saved property ${property.identifier} (${property.address})`);
        } else {
          errors.push(`Failed to link property ${property.identifier} to query: ${linkResult.error}`);
        }
      } catch (error) {
        errors.push(`Exception processing property ${property.identifier}: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    return {
      success: errors.length === 0,
      newCount,
      errors
    };
  }

  /**
   * Process and save properties for a query
   */
  async processPropertiesForQuery(
    query: DbQuery,
    properties: PropertyWithDetails[]
  ): Promise<{ success: boolean; newCount: number; errors: string[] }> {
    const errors: string[] = [];
    let newCount = 0;

    if (properties.length === 0) {
      return { success: true, newCount: 0, errors: [] };
    }

    console.log(`    💾 Saving ${properties.length} new properties to database...`);

    for (const property of properties) {
      try {
        const propertyResult = await this.upsertProperty(property);
        if (!propertyResult.success) {
          errors.push(`Failed to save property ${property.identifier}: ${propertyResult.error}`);
          continue;
        }

        const linkResult = await this.linkPropertyToQuery(query.id!, propertyResult.property!.id!);
        if (linkResult.success) {
          newCount++;
          console.log(`    ✅ Saved property ${property.identifier} (${property.address})`);
        } else {
          errors.push(`Failed to link property ${property.identifier} to query: ${linkResult.error}`);
        }
      } catch (error) {
        errors.push(`Exception processing property ${property.identifier}: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    return {
      success: errors.length === 0,
      newCount,
      errors
    };
  }
}
