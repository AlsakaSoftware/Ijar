import { SupabaseClient } from '@supabase/supabase-js';
import { DbUser } from '../schemas/userSchemas';
import { databaseError } from '../utils/errors';

export class UserRepository {
  constructor(private client: SupabaseClient) {}

  async findById(userId: string): Promise<DbUser | null> {
    const { data, error } = await this.client
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (error || !data) return null;
    return data;
  }

  async upsert(userId: string): Promise<DbUser> {
    const { data, error } = await this.client
      .from('users')
      .upsert(
        { id: userId },
        { onConflict: 'id', ignoreDuplicates: true }
      )
      .select()
      .single();

    if (error) throw databaseError(error.message);
    return data;
  }

  async markOnboardingComplete(userId: string): Promise<void> {
    const { error } = await this.client
      .from('users')
      .update({ has_completed_onboarding: true })
      .eq('id', userId);

    if (error) throw databaseError(error.message);
  }
}
