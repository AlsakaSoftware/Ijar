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
  private supabase: SupabaseClient;
  private productionProvider: Provider;
  private sandboxProvider: Provider;

  constructor(supabase: SupabaseClient) {
    this.supabase = supabase;
    
    // Create providers for both environments
    this.productionProvider = this.createProvider(true);  // production
    this.sandboxProvider = this.createProvider(false);    // sandbox
    
    console.log('🌍 Dual-environment APNs providers initialized (production + sandbox)');
  }

  private createProvider(isProduction: boolean): Provider {
    const options: any = {
      production: isProduction
    };

    // Check for P8 auth key first
    if (process.env.APN_AUTH_KEY && process.env.APN_KEY_ID && process.env.APN_TEAM_ID) {
      console.log(`🔑 Creating ${isProduction ? 'production' : 'sandbox'} provider with P8 key`);
      
      // Write the key to a temporary file to avoid parsing issues
      const fs = require('fs');
      const path = require('path');
      const os = require('os');
      
      const tempDir = os.tmpdir();
      const keyPath = path.join(tempDir, `apn-auth-key-${isProduction ? 'prod' : 'sandbox'}.p8`);
      
      // Clean up the key - handle both escaped \n and quoted format
      let cleanKey = process.env.APN_AUTH_KEY;
      
      // Remove quotes if present
      if (cleanKey.startsWith('"') && cleanKey.endsWith('"')) {
        cleanKey = cleanKey.slice(1, -1);
      }
      
      // Convert \n to actual newlines
      cleanKey = cleanKey.replace(/\\n/g, '\n').trim();
      
      // Validate key format
      if (!cleanKey.includes('-----BEGIN PRIVATE KEY-----') || !cleanKey.includes('-----END PRIVATE KEY-----')) {
        throw new Error('Invalid P8 key format - must contain BEGIN/END PRIVATE KEY markers');
      }
      
      fs.writeFileSync(keyPath, cleanKey);
      
      options.token = {
        key: keyPath,  // Use file path instead of string
        keyId: process.env.APN_KEY_ID,
        teamId: process.env.APN_TEAM_ID
      };
    } else if (process.env.APN_CERT_PATH && process.env.APN_KEY_PATH) {
      console.log('📜 Using certificate files for APNs');
      options.cert = process.env.APN_CERT_PATH;
      options.key = process.env.APN_KEY_PATH;
      options.passphrase = process.env.APN_PASSPHRASE;
    } else {
      const missing = [];
      if (!process.env.APN_AUTH_KEY) missing.push('APN_AUTH_KEY');
      if (!process.env.APN_KEY_ID) missing.push('APN_KEY_ID');
      if (!process.env.APN_TEAM_ID) missing.push('APN_TEAM_ID');
      
      throw new Error(`APNs configuration incomplete. Missing: ${missing.join(', ')}. Either provide P8 key credentials or certificate files.`);
    }

    return new Provider(options);
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

    const tokens = deviceTokens.map(dt => dt.device_token);
    
    // Try both environments for maximum compatibility
    console.log(`📤 Attempting smart dual-environment delivery to ${tokens.length} device(s)`);
    
    return await this.sendWithSmartEnvironmentDetection(userId, payload, tokens);
  }

  private async sendWithSmartEnvironmentDetection(userId: string, payload: NotificationPayload, tokens: string[]): Promise<{ success: boolean; errors: string[] }> {
    const allErrors: string[] = [];
    let totalSent = 0;
    
    // Create notification
    const notification = new Notification();
    notification.topic = process.env.APN_BUNDLE_ID || 'com.yourapp.ijar';
    notification.alert = {
      title: payload.title,
      body: payload.body
    };
    notification.badge = payload.badge || 0;
    notification.sound = 'default';
    notification.contentAvailable = true;
    
    if (payload.data) {
      notification.payload = payload.data;
    }

    // Try production first (for real users)
    console.log(`🏭 Trying production environment first...`);
    const prodResult = await this.sendToEnvironment(this.productionProvider, notification, tokens, 'production');
    totalSent += prodResult.sent.length;
    
    // Check for BadDeviceToken failures - these might be sandbox tokens
    const failedTokens: string[] = [];
    const permanentFailures: string[] = [];
    
    if (prodResult.failed && prodResult.failed.length > 0) {
      for (const failure of prodResult.failed) {
        if (failure.response?.reason === 'BadDeviceToken') {
          failedTokens.push(failure.device);
          console.log(`📱 Token ${failure.device.substring(0, 20)}... failed in production - will try sandbox`);
        } else {
          // Other errors (invalid token, etc.)
          permanentFailures.push(`${failure.device}: ${failure.response?.reason || failure.status}`);
          console.error(`❌ Permanent failure for ${failure.device}: ${failure.response?.reason || failure.status}`);
          
          // Remove permanently invalid tokens
          if (failure.status === '410' || failure.response?.reason === 'Unregistered') {
            await this.removeInvalidToken(failure.device);
          }
        }
      }
    }
    
    // Try sandbox for tokens that failed in production
    if (failedTokens.length > 0) {
      console.log(`🧪 Trying sandbox environment for ${failedTokens.length} failed token(s)...`);
      const sandboxResult = await this.sendToEnvironment(this.sandboxProvider, notification, failedTokens, 'sandbox');
      totalSent += sandboxResult.sent.length;
      
      // Handle remaining failures
      if (sandboxResult.failed && sandboxResult.failed.length > 0) {
        for (const failure of sandboxResult.failed) {
          permanentFailures.push(`${failure.device}: ${failure.response?.reason || failure.status} (both environments)`);
          console.error(`❌ Failed in both environments ${failure.device}: ${failure.response?.reason || failure.status}`);
          
          // Remove tokens that fail in both environments
          if (failure.status === '410' || failure.response?.reason === 'Unregistered' || failure.response?.reason === 'BadDeviceToken') {
            await this.removeInvalidToken(failure.device);
          }
        }
      }
    }
    
    allErrors.push(...permanentFailures);
    
    console.log(`📊 Smart delivery summary: ${totalSent}/${tokens.length} delivered successfully`);
    if (prodResult.sent.length > 0) console.log(`  🏭 Production: ${prodResult.sent.length} sent`);
    if (failedTokens.length > 0) {
      const sandboxSent = totalSent - prodResult.sent.length;
      console.log(`  🧪 Sandbox: ${sandboxSent} sent (${failedTokens.length - sandboxSent} failed)`);
    }
    
    return { 
      success: totalSent > 0 && allErrors.length === 0, 
      errors: allErrors 
    };
  }

  private async sendToEnvironment(provider: Provider, notification: Notification, tokens: string[], env: string): Promise<any> {
    try {
      return await provider.send(notification, tokens);
    } catch (error) {
      console.error(`Error sending to ${env} environment:`, error);
      return { sent: [], failed: tokens.map(token => ({ device: token, error: error instanceof Error ? error.message : 'Unknown error' })) };
    }
  }

  async sendPropertyNotification(userId: string, newPropertyCount: number, queryCount: number, queryName?: string): Promise<{ success: boolean; errors: string[] }> {
    // Dynamic titles based on context
    let title: string;
    let body: string;

    // Choose emoji and title based on property count
    if (newPropertyCount === 1) {
      title = '🔥 New Listing Alert';
    } else if (newPropertyCount <= 5) {
      title = '🏠 New Properties Found';
    } else {
      title = '📍 Property Update';
    }

    const propertyText = newPropertyCount === 1 ? 'property' : 'properties';

    // Craft body message based on context
    // Single property - create urgency
    if (newPropertyCount === 1 && queryCount === 1) {
      if (queryName) {
        body = `New listing just added in ${queryName} - view it now`;
      } else {
        body = `New listing just added - check it out before it's gone`;
      }
    }
    // Multiple searches
    else if (queryCount > 1) {
      body = `${newPropertyCount} new ${propertyText} match your ${queryCount} searches`;
    }
    // Single search with multiple properties
    else {
      if (queryName) {
        if (newPropertyCount <= 3) {
          body = `${newPropertyCount} new ${propertyText} in ${queryName} - don't miss out`;
        } else {
          body = `${newPropertyCount} new ${propertyText} found in ${queryName}`;
        }
      } else {
        body = `${newPropertyCount} new ${propertyText} ready to review`;
      }
    }

    return this.sendNotificationToUser(userId, {
      title,
      body,
      badge: newPropertyCount,
      data: {
        type: 'new_properties',
        count: newPropertyCount,
        queries: queryCount,
        queryName: queryName
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
    console.log('🔌 Shutting down APNs providers...');

    // Force destroy all endpoints and their sockets for production provider
    if (this.productionProvider) {
      try {
        const client = (this.productionProvider as any).client;
        if (client?.endpointManager?._endpoints) {
          console.log(`📱 Force closing ${client.endpointManager._endpoints.length} production endpoint(s)...`);
          client.endpointManager._endpoints.forEach((endpoint: any) => {
            if (endpoint.destroy) {
              endpoint.destroy(); // This destroys the socket and clears intervals
            }
          });
        }
        this.productionProvider.shutdown();
        console.log('📱 Production provider shutdown complete');
      } catch (error) {
        console.error('Error shutting down production provider:', error);
      }
    }

    // Force destroy all endpoints and their sockets for sandbox provider
    if (this.sandboxProvider) {
      try {
        const client = (this.sandboxProvider as any).client;
        if (client?.endpointManager?._endpoints) {
          console.log(`🧪 Force closing ${client.endpointManager._endpoints.length} sandbox endpoint(s)...`);
          client.endpointManager._endpoints.forEach((endpoint: any) => {
            if (endpoint.destroy) {
              endpoint.destroy(); // This destroys the socket and clears intervals
            }
          });
        }
        this.sandboxProvider.shutdown();
        console.log('🧪 Sandbox provider shutdown complete');
      } catch (error) {
        console.error('Error shutting down sandbox provider:', error);
      }
    }

    // Small delay to ensure all resources are released
    await new Promise(resolve => setTimeout(resolve, 100));
    console.log('✅ APNs providers shutdown and connections destroyed');
  }
}