import { SupabaseClient } from '@supabase/supabase-js';
import { supabase } from '../db';
import { DbQuery } from '../types/database';
import { CreateQueryRequest, UpdateQueryRequest } from '../schemas';
import { databaseError } from '../utils/errors';

export class QueryRepository {
  constructor(private client: SupabaseClient = supabase) {}

  async findByUserId(userId: string): Promise<DbQuery[]> {
    const { data, error } = await this.client
      .from('query')
      .select('*')
      .eq('user_id', userId)
      .order('created', { ascending: false });

    if (error) throw databaseError(error.message);
    return data || [];
  }

  async insert(userId: string, query: CreateQueryRequest): Promise<DbQuery> {
    const row: Record<string, unknown> = {
      user_id: userId,
      name: query.name,
      area_name: query.area_name,
      latitude: query.latitude,
      longitude: query.longitude,
      min_price: query.min_price,
      max_price: query.max_price,
      min_bedrooms: query.min_bedrooms,
      max_bedrooms: query.max_bedrooms,
      min_bathrooms: query.min_bathrooms,
      max_bathrooms: query.max_bathrooms,
      radius: query.radius,
      furnish_type: query.furnish_type,
      active: query.active ?? true,
    };

    if (query.id) {
      row.id = query.id;
    }

    const { data, error } = await this.client
      .from('query')
      .insert(row)
      .select()
      .single();

    if (error) throw databaseError(error.message);
    return data;
  }

  async update(queryId: string, userId: string, updates: UpdateQueryRequest): Promise<void> {
    const { error } = await this.client
      .from('query')
      .update(updates)
      .eq('id', queryId)
      .eq('user_id', userId);

    if (error) throw databaseError(error.message);
  }

  async delete(queryId: string, userId: string): Promise<void> {
    const { error } = await this.client
      .from('query')
      .delete()
      .eq('id', queryId)
      .eq('user_id', userId);

    if (error) throw databaseError(error.message);
  }

  async findActive(): Promise<DbQuery[]> {
    const { data, error } = await this.client
      .from('query')
      .select('*')
      .eq('active', true)
      .order('created', { ascending: false });

    if (error) throw databaseError(error.message);
    return data || [];
  }
}
