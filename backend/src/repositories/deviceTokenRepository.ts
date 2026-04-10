import { SupabaseClient } from '@supabase/supabase-js';
import { supabase } from '../db';
import { databaseError } from '../utils/errors';

export class DeviceTokenRepository {
  constructor(private client: SupabaseClient = supabase) {}

  async upsert(userId: string, token: string, platform: string): Promise<void> {
    const { error } = await this.client
      .from('device_tokens')
      .upsert(
        {
          user_id: userId,
          device_token: token,
          platform,
        },
        { onConflict: 'user_id' }
      );

    if (error) throw databaseError(error.message);
  }

  async removeForUser(userId: string): Promise<void> {
    const { error } = await this.client
      .from('device_tokens')
      .delete()
      .eq('user_id', userId);

    if (error) throw databaseError(error.message);
  }
}
