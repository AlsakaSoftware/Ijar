/**
 * Property Save Service
 * Handles all property save/unsave operations
 */

import { SupabaseClient } from '@supabase/supabase-js';
import { Property } from '../types/api';
import { badRequest, databaseError, ErrorCodes } from '../utils/errors';

// Re-export Property type for backwards compatibility
export type SavedProperty = Property;

export class PropertySaveService {
  constructor(private client: SupabaseClient) {}

  /**
   * Save a property for a user
   */
  async saveProperty(userId: string, property: Property): Promise<{ success: boolean; property_id?: string }> {
    const rightmoveId = parseInt(property.id, 10);
    if (isNaN(rightmoveId)) {
      throw badRequest(ErrorCodes.INVALID_PROPERTY_ID, 'Property ID must be numeric');
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
      throw databaseError(propertyError.message);
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
        throw databaseError(updateError.message);
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
      throw databaseError(insertError.message);
    }

    console.log(`✅ Saved property ${rightmoveId}`);
    return { success: true, property_id: propertyUUID };
  }

  /**
   * Unsave a property for a user
   */
  async unsaveProperty(userId: string, rightmoveId: string): Promise<{ success: boolean }> {
    const id = parseInt(rightmoveId, 10);
    if (isNaN(id)) {
      throw badRequest(ErrorCodes.INVALID_PROPERTY_ID, 'Property ID must be numeric');
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
      throw databaseError(updateError.message);
    }

    console.log(`✅ Unsaved property ${id}`);
    return { success: true };
  }

  /**
   * Get all saved properties for a user
   */
  async getSavedProperties(userId: string): Promise<Property[]> {
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

    const properties: Property[] = (data || []).map(row => ({
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
  }

  private async getSavedPropertiesManual(userId: string): Promise<Property[]> {
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
      throw databaseError(propertiesError.message);
    }

    const propertyMap = new Map((properties || []).map(p => [p.id, p]));
    const result: Property[] = [];

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
