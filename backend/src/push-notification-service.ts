import apn, { Provider, Notification } from 'node-apn';
import { SupabaseClient } from '@supabase/supabase-js';

export interface NotificationPayload {
  title: string;
  body: string;
  badge?: number;
  data?: Record<string, any>;
}

export interface DeviceToken {
  id: string;
  user_id: string;
  device_token: string;
  device_type: string;
}

export class PushNotificationService {
  private apnProvider: Provider;
  private supabase: SupabaseClient;

  constructor(supabase: SupabaseClient) {
    this.supabase = supabase;
    
    // Initialize APNs provider
    const options: any = {
      production: process.env.NODE_ENV === 'production'
    };

    if (process.env.APN_AUTH_KEY) {
      // Write the key to a temporary file to avoid parsing issues
      const fs = require('fs');
      const path = require('path');
      const os = require('os');
      
      const tempDir = os.tmpdir();
      const keyPath = path.join(tempDir, 'apn-auth-key.p8');
      
      // Clean up the key - handle both escaped \n and quoted format
      let cleanKey = process.env.APN_AUTH_KEY;
      
      // Remove quotes if present
      if (cleanKey.startsWith('"') && cleanKey.endsWith('"')) {
        cleanKey = cleanKey.slice(1, -1);
      }
      
      // Convert \n to actual newlines
      cleanKey = cleanKey.replace(/\\n/g, '\n').trim();
      
      console.log('Writing P8 key to temp file:', keyPath);
      fs.writeFileSync(keyPath, cleanKey);
      
      options.token = {
        key: keyPath,  // Use file path instead of string
        keyId: process.env.APN_KEY_ID!,
        teamId: process.env.APN_TEAM_ID!
      };
    } else if (process.env.APN_CERT_PATH) {
      options.cert = process.env.APN_CERT_PATH;
      options.key = process.env.APN_KEY_PATH;
      options.passphrase = process.env.APN_PASSPHRASE;
    }

    this.apnProvider = new Provider(options);
  }

  async getDeviceTokensForUser(userId: string): Promise<DeviceToken[]> {
    try {
      const { data, error } = await this.supabase
        .from('device_tokens')
        .select('*')
        .eq('user_id', userId)
        .eq('device_type', 'ios');

      if (error) {
        console.error('Error fetching device tokens:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Exception fetching device tokens:', error);
      return [];
    }
  }

  async sendNotificationToUser(userId: string, payload: NotificationPayload): Promise<{ success: boolean; errors: string[] }> {
    const deviceTokens = await this.getDeviceTokensForUser(userId);
    
    if (deviceTokens.length === 0) {
      console.log(`No device tokens found for user ${userId}`);
      return { success: true, errors: [] };
    }

    const errors: string[] = [];
    const tokens = deviceTokens.map(dt => dt.device_token);

    try {
      // Create notification
      const notification = new Notification();
      notification.topic = process.env.APN_BUNDLE_ID || 'com.yourapp.ijar'; // Update with your bundle ID
      notification.alert = {
        title: payload.title,
        body: payload.body
      };
      notification.badge = payload.badge || 0;
      notification.sound = 'default';
      notification.contentAvailable = true;
      
      // Add custom data
      if (payload.data) {
        notification.payload = payload.data;
      }

      // Send notification
      const result = await this.apnProvider.send(notification, tokens);
      
      // Handle failed tokens
      if (result.failed && result.failed.length > 0) {
        for (const failure of result.failed) {
          console.error(`Failed to send to ${failure.device}:`, failure);
          console.error('  Status:', failure.status);
          console.error('  Response:', failure.response);
          console.error('  Error:', failure.error);
          errors.push(`Device ${failure.device}: ${failure.error || failure.response?.reason || failure.status || 'Unknown error'}`);
          
          // Remove invalid tokens from database
          if (failure.status === '410' || failure.status === '400' || failure.response?.reason === 'BadDeviceToken') {
            await this.removeInvalidToken(failure.device);
          }
        }
      }

      console.log(`Notification sent successfully to ${result.sent.length}/${tokens.length} devices for user ${userId}`);
      return { success: errors.length === 0, errors };

    } catch (error) {
      console.error('Error sending notification:', error);
      return { success: false, errors: [error instanceof Error ? error.message : 'Unknown error'] };
    }
  }

  async sendPropertyNotification(userId: string, newPropertyCount: number, queryCount: number): Promise<{ success: boolean; errors: string[] }> {
    const title = 'New Properties Found!';
    const body = queryCount > 1 
      ? `Found ${newPropertyCount} new properties across ${queryCount} searches`
      : `Found ${newPropertyCount} new ${newPropertyCount === 1 ? 'property' : 'properties'}`;

    return this.sendNotificationToUser(userId, {
      title,
      body,
      badge: newPropertyCount,
      data: {
        type: 'new_properties',
        count: newPropertyCount,
        queries: queryCount
      }
    });
  }

  private async removeInvalidToken(deviceToken: string): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('device_tokens')
        .delete()
        .eq('device_token', deviceToken);

      if (error) {
        console.error('Error removing invalid token:', error);
      } else {
        console.log(`Removed invalid device token: ${deviceToken}`);
      }
    } catch (error) {
      console.error('Exception removing invalid token:', error);
    }
  }

  async cleanup(): Promise<void> {
    if (this.apnProvider) {
      this.apnProvider.shutdown();
    }
  }
}