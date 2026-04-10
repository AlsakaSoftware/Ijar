import { SupabaseClient } from '@supabase/supabase-js';
import { supabase } from '../db';
import { DbProperty } from '../types/database';
import { databaseError } from '../utils/errors';

export class PropertyRepository {
  constructor(private client: SupabaseClient = supabase) {}

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
    // Query tables directly instead of property_feed view,
    // because the view uses auth.uid() which is NULL when using the service role key
    const { data: queryIds, error: queryError } = await this.client
      .from('query')
      .select('id')
      .eq('user_id', userId)
      .eq('active', true);

    if (queryError) throw databaseError(queryError.message);
    if (!queryIds || queryIds.length === 0) return [];

    // Get property IDs linked to these queries
    const { data: links, error: linkError } = await this.client
      .from('query_property')
      .select('property_id, found_at')
      .in('query_id', queryIds.map(q => q.id))
      .order('found_at', { ascending: false });

    if (linkError) throw databaseError(linkError.message);
    if (!links || links.length === 0) return [];

    // Get property IDs the user has already interacted with (saved/passed)
    const { data: actions } = await this.client
      .from('user_property_action')
      .select('property_id')
      .eq('user_id', userId);

    const seenIds = new Set((actions || []).map(a => a.property_id));

    // Filter out seen properties and deduplicate
    const unseenPropertyIds = [...new Set(
      links
        .filter(l => !seenIds.has(l.property_id))
        .map(l => l.property_id)
    )];

    if (unseenPropertyIds.length === 0) return [];

    // Fetch the actual properties
    const { data: properties, error: propError } = await this.client
      .from('property')
      .select('*')
      .in('id', unseenPropertyIds);

    if (propError) throw databaseError(propError.message);
    return properties || [];
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
