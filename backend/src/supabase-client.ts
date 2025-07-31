import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { RightmoveProperty, RightmoveStation } from './scraper-types';

// Database types
export interface DatabaseProperty {
  id?: string;
  rightmove_id: number;
  images: string[];
  price: string;
  bedrooms: number;
  bathrooms: number;
  address: string;
  area?: string;
  latitude?: number;
  longitude?: number;
  nearest_tube_station?: string;
  tube_station_distance?: number;
  nearby_stations?: RightmoveStation[];
  transport_description?: string;
  property_url?: string;
  contact_url?: string;
  summary?: string;
  property_type?: string;
  display_size?: string;
  number_of_images?: number;
  first_visible_date?: string;
  agent_name?: string;
  agent_phone?: string;
  brand_name?: string;
  search_name?: string;
  first_seen?: string;
  last_updated?: string;
  is_active?: boolean;
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

    // Find nearest tube/underground station
    let nearestTubeStation: string | undefined;
    let tubeStationDistance: number | undefined;

    if (property.nearbyStations && property.nearbyStations.length > 0) {
      // Find the nearest London Underground station
      const tubeStation = property.nearbyStations
        .filter(station => station.types.includes('LONDON_UNDERGROUND'))
        .sort((a, b) => a.distance - b.distance)[0];

      if (tubeStation) {
        nearestTubeStation = tubeStation.name;
        tubeStationDistance = tubeStation.distance;
      } else {
        // If no tube station, use the nearest station of any type
        const nearestStation = property.nearbyStations
          .sort((a, b) => a.distance - b.distance)[0];
        nearestTubeStation = nearestStation.name;
        tubeStationDistance = nearestStation.distance;
      }
    }

    return {
      rightmove_id: property.id,
      images: property.images.map(img => img.srcUrl || img.url),
      price: property.price?.displayPrices?.[0]?.displayPrice || 'Price on request',
      bedrooms: property.bedrooms || 0,
      bathrooms: property.bathrooms || 0,
      address: property.displayAddress,
      area,
      latitude: property.location?.latitude,
      longitude: property.location?.longitude,
      nearest_tube_station: nearestTubeStation,
      tube_station_distance: tubeStationDistance,
      nearby_stations: property.nearbyStations,
      transport_description: property.transportDescription,
      property_url: property.propertyUrl,
      contact_url: property.contactUrl,
      summary: property.summary,
      property_type: property.propertyTypeFullDescription,
      display_size: property.displaySize,
      number_of_images: property.numberOfImages || 0,
      first_visible_date: property.firstVisibleDate,
      agent_name: property.agent?.name || property.brand?.branchDisplayName,
      agent_phone: property.agent?.phone || property.brand?.contactTelephone,
      brand_name: property.brand?.brandTradingName,
      search_name: searchName,
      is_active: true
    };
  }

  // Insert a new property (with upsert to handle duplicates)
  async upsertProperty(property: RightmoveProperty, searchName?: string): Promise<{ success: boolean; property?: DatabaseProperty; error?: string }> {
    try {
      const dbProperty = this.mapRightmoveToDatabase(property, searchName);
      
      const { data, error } = await this.supabase
        .from('properties')
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
        .from('properties')
        .select('*')
        .eq('search_name', searchName)
        .eq('is_active', true)
        .order('first_seen', { ascending: false })
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
        .from('properties')
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
        .from('properties')
        .update({ is_active: false })
        .eq('search_name', searchName)
        .lt('last_updated', cutoffDate.toISOString())
        .eq('is_active', true)
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