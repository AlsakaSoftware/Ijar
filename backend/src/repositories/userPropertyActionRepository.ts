import { SupabaseClient } from '@supabase/supabase-js';
import { databaseError } from '../utils/errors';

export interface UserPropertyAction {
  user_id: string;
  property_id: string;
  action: 'saved' | 'passed';
  created?: string;
}

export class UserPropertyActionRepository {
  constructor(private client: SupabaseClient) {}

  async findAction(userId: string, propertyId: string): Promise<{ action: string } | null> {
    const { data } = await this.client
      .from('user_property_action')
      .select('action')
      .eq('user_id', userId)
      .eq('property_id', propertyId)
      .single();

    return data;
  }

  async insertAction(userId: string, propertyId: string, action: string): Promise<void> {
    const { error } = await this.client
      .from('user_property_action')
      .insert({ user_id: userId, property_id: propertyId, action });

    if (error) throw databaseError(error.message);
  }

  async updateAction(userId: string, propertyId: string, action: string): Promise<void> {
    const { error } = await this.client
      .from('user_property_action')
      .update({ action })
      .eq('user_id', userId)
      .eq('property_id', propertyId);

    if (error) throw databaseError(error.message);
  }

  async getSavedPropertyIds(userId: string): Promise<string[]> {
    const { data, error } = await this.client
      .from('user_property_action')
      .select('property_id, created')
      .eq('user_id', userId)
      .eq('action', 'saved')
      .order('created', { ascending: false });

    if (error || !data) return [];
    return data.map(a => a.property_id);
  }

  async getSavedPropertiesFromView(userId: string): Promise<any[] | null> {
    const { data, error } = await this.client
      .from('saved_properties')
      .select('*')
      .eq('user_id', userId);

    if (error) return null;
    return data;
  }
}
