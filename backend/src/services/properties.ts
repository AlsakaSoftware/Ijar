/**
 * Property Save Service
 * Handles all property save/unsave operations
 */

import { SupabaseClient } from '@supabase/supabase-js';

// Input format from iOS (camelCase for convenience)
export interface PropertyData {
  id: string;
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
}

// Output format (snake_case for iOS CodingKeys)
export interface SavedProperty {
  id: string;
  images: string[];
  price: string;
  bedrooms: number;
  bathrooms: number;
  address: string;
  area: string | null;
  rightmove_url: string | null;
  agent_phone: string | null;
  agent_name: string | null;
  branch_name: string | null;
  latitude: number | null;
  longitude: number | null;
}

export class PropertySaveService {
  constructor(private client: SupabaseClient) {}

  /**
   * Save a property for a user
   */
  async saveProperty(userId: string, property: PropertyData): Promise<{ success: boolean; property_id?: string; error?: string }> {
    try {
      const rightmoveId = parseInt(property.id, 10);
      if (isNaN(rightmoveId)) {
        return { success: false, error: 'Invalid property ID' };
      }

      console.log(`💾 Saving property ${rightmoveId} for user ${userId}`);

      // 1. Upsert property
      const { data: propertyData, error: propertyError } = await this.client
        .from('property')
        .upsert({
          rightmove_id: rightmoveId,
          images: property.images,
          price: property.price,
          bedrooms: property.bedrooms,
          bathrooms: property.bathrooms,
          address: property.address,
          area: property.area || null,
          rightmove_url: property.rightmove_url || `https://www.rightmove.co.uk/properties/${rightmoveId}`,
          agent_phone: property.agent_phone || null,
          agent_name: property.agent_name || null,
          branch_name: property.branch_name || null,
          latitude: property.latitude || null,
          longitude: property.longitude || null
        }, {
          onConflict: 'rightmove_id',
          ignoreDuplicates: false
        })
        .select('id')
        .single();

      if (propertyError) {
        console.error('Error upserting property:', propertyError);
        return { success: false, error: propertyError.message };
      }

      const propertyUUID = propertyData.id;

      // 2. Check for existing action
      const { data: existingAction } = await this.client
        .from('user_property_action')
        .select('action')
        .eq('user_id', userId)
        .eq('property_id', propertyUUID)
        .single();

      if (existingAction) {
        if (existingAction.action === 'saved') {
          console.log(`✅ Property already saved`);
          return { success: true, property_id: propertyUUID };
        }

        // Update from "passed" to "saved"
        const { error: updateError } = await this.client
          .from('user_property_action')
          .update({ action: 'saved' })
          .eq('user_id', userId)
          .eq('property_id', propertyUUID);

        if (updateError) {
          return { success: false, error: updateError.message };
        }

        console.log(`✅ Updated action to saved`);
        return { success: true, property_id: propertyUUID };
      }

      // 3. Insert new action
      const { error: insertError } = await this.client
        .from('user_property_action')
        .insert({
          user_id: userId,
          property_id: propertyUUID,
          action: 'saved'
        });

      if (insertError) {
        return { success: false, error: insertError.message };
      }

      console.log(`✅ Saved property ${rightmoveId}`);
      return { success: true, property_id: propertyUUID };

    } catch (error) {
      console.error('Exception saving property:', error);
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  /**
   * Unsave a property for a user
   */
  async unsaveProperty(userId: string, rightmoveId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const id = parseInt(rightmoveId, 10);
      if (isNaN(id)) {
        return { success: false, error: 'Invalid property ID' };
      }

      console.log(`🗑️ Unsaving property ${id} for user ${userId}`);

      // Find property by rightmove_id
      const { data: property, error: findError } = await this.client
        .from('property')
        .select('id')
        .eq('rightmove_id', id)
        .single();

      if (findError || !property) {
        console.log('Property not found in database');
        return { success: true };
      }

      // Update action to passed
      const { error: updateError } = await this.client
        .from('user_property_action')
        .update({ action: 'passed' })
        .eq('user_id', userId)
        .eq('property_id', property.id);

      if (updateError) {
        return { success: false, error: updateError.message };
      }

      console.log(`✅ Unsaved property ${id}`);
      return { success: true };

    } catch (error) {
      console.error('Exception unsaving property:', error);
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  /**
   * Get all saved properties for a user (returns snake_case)
   */
  async getSavedProperties(userId: string): Promise<SavedProperty[]> {
    try {
      console.log(`📋 Loading saved properties for user ${userId}`);

      // Try using the saved_properties view first
      const { data, error } = await this.client
        .from('saved_properties')
        .select('*')
        .eq('user_id', userId);

      if (error) {
        console.error('Error loading saved properties:', error);
        return await this.getSavedPropertiesManual(userId);
      }

      const properties: SavedProperty[] = (data || []).map(row => ({
        id: String(row.rightmove_id),
        images: row.images || [],
        price: row.price,
        bedrooms: row.bedrooms,
        bathrooms: row.bathrooms,
        address: row.address,
        area: row.area || null,
        rightmove_url: row.rightmove_url || null,
        agent_phone: row.agent_phone || null,
        agent_name: row.agent_name || null,
        branch_name: row.branch_name || null,
        latitude: row.latitude || null,
        longitude: row.longitude || null
      }));

      console.log(`✅ Loaded ${properties.length} saved properties`);
      return properties;

    } catch (error) {
      console.error('Exception loading saved properties:', error);
      return [];
    }
  }

  private async getSavedPropertiesManual(userId: string): Promise<SavedProperty[]> {
    const { data: actions, error: actionsError } = await this.client
      .from('user_property_action')
      .select('property_id, created')
      .eq('user_id', userId)
      .eq('action', 'saved')
      .order('created', { ascending: false });

    if (actionsError || !actions || actions.length === 0) {
      return [];
    }

    const propertyIds = actions.map(a => a.property_id);

    const { data: properties, error: propertiesError } = await this.client
      .from('property')
      .select('*')
      .in('id', propertyIds);

    if (propertiesError) {
      return [];
    }

    const propertyMap = new Map((properties || []).map(p => [p.id, p]));
    const result: SavedProperty[] = [];

    for (const action of actions) {
      const prop = propertyMap.get(action.property_id);
      if (prop) {
        result.push({
          id: String(prop.rightmove_id),
          images: prop.images || [],
          price: prop.price,
          bedrooms: prop.bedrooms,
          bathrooms: prop.bathrooms,
          address: prop.address,
          area: prop.area || null,
          rightmove_url: prop.rightmove_url || null,
          agent_phone: prop.agent_phone || null,
          agent_name: prop.agent_name || null,
          branch_name: prop.branch_name || null,
          latitude: prop.latitude || null,
          longitude: prop.longitude || null
        });
      }
    }

    return result;
  }
}
