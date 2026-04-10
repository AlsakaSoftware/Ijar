import { SupabaseClient } from '@supabase/supabase-js';
import { databaseError } from '../utils/errors';

export interface DbGroup {
  id: string;
  user_id: string;
  name: string;
  created_at: string;
}

export class GroupRepository {
  constructor(private client: SupabaseClient) {}

  async findByUserId(userId: string): Promise<DbGroup[]> {
    const { data, error } = await this.client
      .from('property_group')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw databaseError(error.message);
    return data || [];
  }

  async create(userId: string, name: string): Promise<DbGroup> {
    const { data, error } = await this.client
      .from('property_group')
      .insert({ user_id: userId, name })
      .select()
      .single();

    if (error) throw databaseError(error.message);
    return data;
  }

  async delete(groupId: string): Promise<void> {
    const { error } = await this.client
      .from('property_group')
      .delete()
      .eq('id', groupId);

    if (error) throw databaseError(error.message);
  }

  async rename(groupId: string, name: string): Promise<void> {
    const { error } = await this.client
      .from('property_group')
      .update({ name })
      .eq('id', groupId);

    if (error) throw databaseError(error.message);
  }
}
