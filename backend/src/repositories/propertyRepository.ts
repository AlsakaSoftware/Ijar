import { SupabaseClient } from '@supabase/supabase-js';
import { DbProperty } from '../types/database';
import { databaseError } from '../utils/errors';

export class PropertyRepository {
  constructor(private client: SupabaseClient) {}

  async findByRightmoveId(rightmoveId: number): Promise<{ id: string } | null> {
    const { data, error } = await this.client
      .from('property')
      .select('id')
      .eq('rightmove_id', rightmoveId)
      .single();

    if (error || !data) return null;
    return data;
  }

  async upsert(property: DbProperty): Promise<{ id: string }> {
    const { data, error } = await this.client
      .from('property')
      .upsert(property, {
        onConflict: 'rightmove_id',
        ignoreDuplicates: false,
      })
      .select('id')
      .single();

    if (error) throw databaseError(error.message);
    return data;
  }

  async findByIds(ids: string[]): Promise<DbProperty[]> {
    if (ids.length === 0) return [];

    const { data, error } = await this.client
      .from('property')
      .select('*')
      .in('id', ids);

    if (error) throw databaseError(error.message);
    return data || [];
  }

  async getFeedForUser(userId: string): Promise<DbProperty[]> {
    const { data, error } = await this.client
      .from('property_feed')
      .select('*')
      .eq('user_id', userId);

    if (error) throw databaseError(error.message);
    return data || [];
  }

  async upsertAndLinkToQuery(queryId: string, property: DbProperty): Promise<{ id: string }> {
    const result = await this.upsert(property);

    await this.client
      .from('query_property')
      .upsert(
        { query_id: queryId, property_id: result.id },
        { onConflict: 'query_id,property_id', ignoreDuplicates: true }
      );

    return result;
  }
}
