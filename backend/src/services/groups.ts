/**
 * Group Service
 * Handles property group operations
 */

import { SupabaseClient } from '@supabase/supabase-js';
import { SavedProperty } from './properties';

// Output format (snake_case for iOS CodingKeys)
export interface PropertyGroup {
  id: string;
  user_id: string;
  name: string;
  created_at: string;
  property_count: number;
}

export class GroupService {
  constructor(private client: SupabaseClient) {}

  /**
   * Get all groups for a user with property counts
   */
  async getGroups(userId: string): Promise<PropertyGroup[]> {
    try {
      console.log(`📁 Loading groups for user ${userId}`);

      const { data: groupRows, error: groupError } = await this.client
        .from('property_group')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (groupError || !groupRows) {
        return [];
      }

      // Get property counts for all groups in one query
      const groupIds = groupRows.map(g => g.id);
      const { data: members } = await this.client
        .from('property_group_member')
        .select('group_id')
        .in('group_id', groupIds);

      const countsByGroup: Record<string, number> = {};
      for (const member of members || []) {
        countsByGroup[member.group_id] = (countsByGroup[member.group_id] || 0) + 1;
      }

      const groups: PropertyGroup[] = groupRows.map(row => ({
        id: row.id,
        user_id: row.user_id,
        name: row.name,
        created_at: row.created_at,
        property_count: countsByGroup[row.id] || 0
      }));

      console.log(`✅ Loaded ${groups.length} groups`);
      return groups;

    } catch (error) {
      console.error('Exception loading groups:', error);
      return [];
    }
  }

  /**
   * Create a new group
   */
  async createGroup(userId: string, name: string): Promise<{ group?: PropertyGroup; error?: string }> {
    try {
      console.log(`➕ Creating group "${name}" for user ${userId}`);

      const { data, error } = await this.client
        .from('property_group')
        .insert({ user_id: userId, name })
        .select()
        .single();

      if (error) {
        return { error: error.message };
      }

      const group: PropertyGroup = {
        id: data.id,
        user_id: data.user_id,
        name: data.name,
        created_at: data.created_at,
        property_count: 0
      };

      console.log(`✅ Created group ${group.id}`);
      return { group };

    } catch (error) {
      console.error('Exception creating group:', error);
      return { error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  /**
   * Delete a group
   */
  async deleteGroup(groupId: string): Promise<{ success: boolean; error?: string }> {
    try {
      console.log(`🗑️ Deleting group ${groupId}`);

      // Delete members first
      await this.client
        .from('property_group_member')
        .delete()
        .eq('group_id', groupId);

      // Delete group
      const { error } = await this.client
        .from('property_group')
        .delete()
        .eq('id', groupId);

      if (error) {
        return { success: false, error: error.message };
      }

      console.log(`✅ Deleted group`);
      return { success: true };

    } catch (error) {
      console.error('Exception deleting group:', error);
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  /**
   * Rename a group
   */
  async renameGroup(groupId: string, name: string): Promise<{ success: boolean; error?: string }> {
    try {
      console.log(`✏️ Renaming group ${groupId} to "${name}"`);

      const { error } = await this.client
        .from('property_group')
        .update({ name })
        .eq('id', groupId);

      if (error) {
        return { success: false, error: error.message };
      }

      console.log(`✅ Renamed group`);
      return { success: true };

    } catch (error) {
      console.error('Exception renaming group:', error);
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  /**
   * Get properties in a group (returns snake_case)
   */
  async getPropertiesInGroup(groupId: string): Promise<SavedProperty[]> {
    try {
      console.log(`📋 Loading properties for group ${groupId}`);

      // Get member property IDs
      const { data: members, error: memberError } = await this.client
        .from('property_group_member')
        .select('property_id')
        .eq('group_id', groupId);

      if (memberError || !members || members.length === 0) {
        return [];
      }

      const propertyIds = members.map(m => m.property_id);

      // Get property details
      const { data: properties, error: propError } = await this.client
        .from('property')
        .select('*')
        .in('id', propertyIds);

      if (propError) {
        return [];
      }

      const result: SavedProperty[] = (properties || []).map(prop => ({
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
      }));

      console.log(`✅ Loaded ${result.length} properties for group`);
      return result;

    } catch (error) {
      console.error('Exception loading group properties:', error);
      return [];
    }
  }

  /**
   * Add a property to a group
   */
  async addPropertyToGroup(groupId: string, rightmoveId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const id = parseInt(rightmoveId, 10);
      if (isNaN(id)) {
        return { success: false, error: 'Invalid property ID' };
      }

      console.log(`➕ Adding property ${id} to group ${groupId}`);

      // Find property by rightmove_id
      const { data: property, error: findError } = await this.client
        .from('property')
        .select('id')
        .eq('rightmove_id', id)
        .single();

      if (findError || !property) {
        return { success: false, error: 'Property not found' };
      }

      // Add to group (upsert to handle duplicates)
      const { error } = await this.client
        .from('property_group_member')
        .upsert({
          group_id: groupId,
          property_id: property.id
        }, {
          onConflict: 'group_id,property_id',
          ignoreDuplicates: true
        });

      if (error) {
        return { success: false, error: error.message };
      }

      console.log(`✅ Added property to group`);
      return { success: true };

    } catch (error) {
      console.error('Exception adding property to group:', error);
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  /**
   * Remove a property from a group
   */
  async removePropertyFromGroup(groupId: string, rightmoveId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const id = parseInt(rightmoveId, 10);
      if (isNaN(id)) {
        return { success: false, error: 'Invalid property ID' };
      }

      console.log(`➖ Removing property ${id} from group ${groupId}`);

      // Find property by rightmove_id
      const { data: property, error: findError } = await this.client
        .from('property')
        .select('id')
        .eq('rightmove_id', id)
        .single();

      if (findError || !property) {
        return { success: true }; // Nothing to remove
      }

      // Remove from group
      const { error } = await this.client
        .from('property_group_member')
        .delete()
        .eq('group_id', groupId)
        .eq('property_id', property.id);

      if (error) {
        return { success: false, error: error.message };
      }

      console.log(`✅ Removed property from group`);
      return { success: true };

    } catch (error) {
      console.error('Exception removing property from group:', error);
      return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
    }
  }

  /**
   * Get groups that contain a property
   */
  async getGroupsForProperty(userId: string, rightmoveId: string): Promise<string[]> {
    try {
      const id = parseInt(rightmoveId, 10);
      if (isNaN(id)) {
        return [];
      }

      // Find property by rightmove_id
      const { data: property, error: findError } = await this.client
        .from('property')
        .select('id')
        .eq('rightmove_id', id)
        .single();

      if (findError || !property) {
        return [];
      }

      // Get groups this property is in (for this user only)
      const { data: members, error: memberError } = await this.client
        .from('property_group_member')
        .select('group_id, property_group!inner(user_id)')
        .eq('property_id', property.id)
        .eq('property_group.user_id', userId);

      if (memberError) {
        return [];
      }

      return (members || []).map(m => m.group_id);

    } catch (error) {
      console.error('Exception getting groups for property:', error);
      return [];
    }
  }
}
