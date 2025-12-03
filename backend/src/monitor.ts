#!/usr/bin/env tsx

import 'dotenv/config';
import { RightmoveAPI, RightmoveAPIProperty, RightmoveAPIPropertyDetails } from './rightmove-api';
import { SupabasePropertyClient, UserQuery } from './supabase-client';

// Extended property type with HD images from details API
interface PropertyWithDetails extends RightmoveAPIProperty {
  hdImages?: string[];
  bathrooms?: number;
}
import config from './config';
import { PushNotificationService } from './push-notification-service';
import { createClient } from '@supabase/supabase-js';

class PropertyMonitor {
  private api: RightmoveAPI;
  private supabase: SupabasePropertyClient;
  private notificationService: PushNotificationService;

  constructor() {
    this.api = new RightmoveAPI();
    this.supabase = new SupabasePropertyClient();

    const supabaseClient = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );

    this.notificationService = new PushNotificationService(supabaseClient);
  }

  // Log data quality metrics for properties
  private logDataQuality(properties: RightmoveAPIProperty[], queryName: string): void {
    if (properties.length === 0) return;

    let missingAgentPhone = 0;
    let missingAgentName = 0;
    let missingBranchName = 0;

    properties.forEach((property, index) => {
      const hasPhone = property.branch?.contactTelephoneNumber;
      const hasAgentName = property.branch?.brandName;
      const hasBranchName = property.branch?.name;

      if (!hasPhone) {
        missingAgentPhone++;
        console.log(`    ⚠️  Property ${index + 1} (${property.address}) missing agent phone`);
      }
      if (!hasAgentName) {
        missingAgentName++;
        console.log(`    ⚠️  Property ${index + 1} (${property.address}) missing agent name`);
      }
      if (!hasBranchName) {
        missingBranchName++;
        console.log(`    ⚠️  Property ${index + 1} (${property.address}) missing branch name`);
      }
    });

    // Summary log
    const total = properties.length;
    console.log(`    📈 Data Quality for "${queryName}":`);
    console.log(`      📞 Agent Phone: ${total - missingAgentPhone}/${total} (${Math.round((total - missingAgentPhone) / total * 100)}%)`);
    console.log(`      👤 Agent Name: ${total - missingAgentName}/${total} (${Math.round((total - missingAgentName) / total * 100)}%)`);
    console.log(`      🏢 Branch Name: ${total - missingBranchName}/${total} (${Math.round((total - missingBranchName) / total * 100)}%)`);

    // Alert if data quality is poor
    const phoneSuccessRate = (total - missingAgentPhone) / total;
    const nameSuccessRate = (total - missingAgentName) / total;

    if (phoneSuccessRate < 0.8) {
      console.log(`    🚨 LOW PHONE DATA QUALITY: Only ${Math.round(phoneSuccessRate * 100)}% of properties have agent phone numbers`);
    }
    if (nameSuccessRate < 0.8) {
      console.log(`    🚨 LOW NAME DATA QUALITY: Only ${Math.round(nameSuccessRate * 100)}% of properties have agent names`);
    }
  }

  // Helper function to group queries by user_id
  private groupQueriesByUser(queries: UserQuery[]): Map<string, UserQuery[]> {
    const grouped = new Map<string, UserQuery[]>();

    for (const query of queries) {
      if (!query.user_id) continue; // Skip queries without user_id

      if (!grouped.has(query.user_id)) {
        grouped.set(query.user_id, []);
      }
      grouped.get(query.user_id)!.push(query);
    }

    return grouped;
  }

  async run(targetUserId?: string): Promise<void> {
    const timestamp = new Date().toLocaleString();
    if (targetUserId) {
      console.log(`[${timestamp}] 🔍 Processing queries for user: ${targetUserId}`);
    } else {
      console.log(`[${timestamp}] 🔍 Processing all user queries from database`);
    }

    try {
      // Get all active queries from Supabase
      const userQueries = await this.supabase.getActiveQueries();
      console.log(`📊 Found ${userQueries.length} active user queries`);

      if (userQueries.length === 0) {
        console.log('📭 No active queries to process');
        return;
      }

      // Filter by user if targetUserId is provided
      const filteredQueries = targetUserId
        ? userQueries.filter(q => q.user_id?.toLowerCase() === targetUserId.toLowerCase())
        : userQueries;

      if (targetUserId && filteredQueries.length === 0) {
        console.log(`📭 No active queries found for user: ${targetUserId}`);
        return;
      }

      // Group queries by user_id
      const queriesByUser = this.groupQueriesByUser(filteredQueries);
      console.log(`👥 Processing queries for ${queriesByUser.size} users`);

      let totalNewProperties = 0;

      // Process each user's queries
      for (const [userId, queries] of queriesByUser) {
        console.log(`\n👤 Processing ${queries.length} queries for user: ${userId}`);
        let userNewProperties = 0;

        // Process all queries for this user
        for (const query of queries) {
          console.log(`  🔍 Processing query: ${query.name}`);

          try {
            const processResult = await this.processQuery(query);
            userNewProperties += processResult.newCount;

            if (processResult.newCount > 0) {
              console.log(`    🎉 Added ${processResult.newCount} new properties for query: ${query.name}`);
            } else {
              console.log(`    📭 No new properties for query: ${query.name}`);
            }

            if (processResult.errors.length > 0) {
              console.warn(`    ⚠️ Some errors occurred:`, processResult.errors.slice(0, 3));
            }

          } catch (error) {
            console.error(`    ❌ Error processing query ${query.name}:`, error);
          }
        }

        if (userNewProperties > 0 && this.notificationService) {
          console.log(`  🔔 Sending notification to user ${userId}: ${userNewProperties} new properties across ${queries.length} queries`);

          try {
            // Include query name for single query notifications
            const queryName = queries.length === 1 ? queries[0].name : undefined;

            const notificationResult = await this.notificationService.sendPropertyNotification(
              userId,
              userNewProperties,
              queries.length,
              queryName
            );

            if (notificationResult.success) {
              console.log(`  ✅ Notification sent successfully to user ${userId}`);
            } else {
              console.warn(`  ⚠️ Notification failed for user ${userId}:`, notificationResult.errors);
            }
          } catch (error) {
            console.error(`  ❌ Error sending notification to user ${userId}:`, error);
          }
        } else {
          console.log(`  📭 No new properties for user ${userId}, skipping notification`);
        }

        totalNewProperties += userNewProperties;
      }

      console.log(`\n✅ Completed processing all queries. Total new properties: ${totalNewProperties}`);

    } catch (error) {
      console.error('❌ Error processing user queries:', error);
    }
  }

  private async processQuery(query: UserQuery): Promise<{ newCount: number; errors: string[] }> {
    try {
      // Search using API with coordinates
      const results = await this.api.searchProperties({
        latitude: query.latitude,
        longitude: query.longitude,
        minPrice: query.min_price,
        maxPrice: query.max_price,
        minBedrooms: query.min_bedrooms,
        maxBedrooms: query.max_bedrooms,
        minBathrooms: query.min_bathrooms,
        maxBathrooms: query.max_bathrooms,
        radius: query.radius,
        furnishType: query.furnish_type as 'furnished' | 'unfurnished' | undefined,
        page: 1,
        pageSize: 25
      });

      console.log(`    📊 API returned ${results.properties.length} properties (total: ${results.total})`);

      // Filter for properties that are NEW for this specific query
      const newPropertiesForQuery = await this.supabase.getNewAPIPropertiesForQuery(query, results.properties);
      console.log(`    🔍 ${newPropertiesForQuery.length} are new (${results.properties.length - newPropertiesForQuery.length} already seen)`);

      if (newPropertiesForQuery.length === 0) {
        console.log(`    📭 No new properties to process for query: ${query.name}`);
        return { newCount: 0, errors: [] };
      }

      // Take top N new properties (e.g., top 7)
      const topNewProperties = newPropertiesForQuery.slice(0, config.maxHDPropertiesPerQuery);
      console.log(`    🎯 Processing top ${topNewProperties.length} new properties`);

      // Log data quality metrics for the properties we're about to process
      this.logDataQuality(topNewProperties, query.name);

      // Fetch HD images for each property
      console.log(`    📸 Fetching HD images for ${topNewProperties.length} properties...`);
      const propertiesWithDetails = await this.fetchPropertyDetails(topNewProperties);

      // Process properties for this specific query
      const processResult = await this.supabase.processAPIPropertiesForQuery(query, propertiesWithDetails);

      return {
        newCount: processResult.newCount,
        errors: processResult.errors
      };

    } catch (error) {
      console.error(`    ❌ Error processing query ${query.name}:`, error);
      return {
        newCount: 0,
        errors: [error instanceof Error ? error.message : 'Unknown error']
      };
    }
  }

  // Fetch property details to get HD images
  private async fetchPropertyDetails(properties: RightmoveAPIProperty[]): Promise<PropertyWithDetails[]> {
    const results: PropertyWithDetails[] = [];

    for (const property of properties) {
      try {
        const details = await this.api.getPropertyDetails(property.identifier);
        const p = details.property;

        // Extract HD images from details
        const hdImages = p.photos?.map((photo: any) => photo.maxSizeUrl) || [];
        const bathrooms = parseInt(p.analyticsInfo?.bathrooms || '0', 10);

        console.log(`      📷 ${property.identifier}: ${hdImages.length} HD images, ${bathrooms} bathrooms`);

        results.push({
          ...property,
          hdImages,
          bathrooms
        });
      } catch (error) {
        console.warn(`      ⚠️ Failed to fetch details for ${property.identifier}, using thumbnails`);
        // Fall back to thumbnail images
        results.push(property);
      }
    }

    return results;
  }

  // Cleanup method to properly close connections
  async cleanup(): Promise<void> {
    if (this.notificationService) {
      await this.notificationService.cleanup();
    }
  }
}

// Main execution
async function main() {
  // Check if user ID was passed as command-line argument
  const targetUserId = process.argv[2];

  if (targetUserId) {
    console.log(`Processing queries for user: ${targetUserId}`);
  } else {
    console.log('Processing all user queries from Supabase database...');
  }

  const monitor = new PropertyMonitor();

  try {
    await monitor.run(targetUserId);
  } finally {
    // Always cleanup
    if (monitor.cleanup) {
      await monitor.cleanup();
      console.log('🧹 Cleanup completed');
    }

    // Force exit after a short delay to ensure all logs are flushed
    setTimeout(() => {
      console.log('✅ Monitor workflow completed successfully');
      process.exit(0);
    }, 1000);
  }
}

// Run if this file is executed directly
if (require.main === module) {
  main();
}
