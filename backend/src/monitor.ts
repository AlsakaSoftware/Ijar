#!/usr/bin/env tsx

import 'dotenv/config';
import RightmoveScraper from './rightmove-scraper';
import { SupabasePropertyClient, UserQuery } from './supabase-client';
import { SearchOptions } from './scraper-types';
import config from './config';
import { PushNotificationService } from './push-notification-service';
import { createClient } from '@supabase/supabase-js';

class PropertyMonitor {
  private scraper: RightmoveScraper;
  private supabase: SupabasePropertyClient;
  private notificationService: PushNotificationService;

  constructor() {
    this.scraper = new RightmoveScraper();
    this.supabase = new SupabasePropertyClient();
    
    // Initialize notification service with Supabase client
    const supabaseClient = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );
    
    // Try to initialize push notification service
    try {
      this.notificationService = new PushNotificationService(supabaseClient);
      console.log('✅ Push notification service initialized');
    } catch (error) {
      console.warn('⚠️ Push notifications disabled - failed to initialize:', error instanceof Error ? error.message : error);
      // Continue without push notifications
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

  // Process all queries for a single user
  private async processUserQueries(userId: string, queries: UserQuery[]): Promise<number> {
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
    
    // Send notification if user has new properties
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
    } else if (userNewProperties > 0) {
      console.log(`  ℹ️ Would send notification for ${userNewProperties} new properties, but push service not available`);
    } else {
      console.log(`  📭 No new properties for user ${userId}, skipping notification`);
    }
    
    return userNewProperties;
  }

  async run(): Promise<void> {
    const timestamp = new Date().toLocaleString();
    console.log(`[${timestamp}] 🔍 Processing all user queries from database`);
    
    try {
      // Get all active queries from Supabase
      const userQueries = await this.supabase.getActiveQueries();
      console.log(`📊 Found ${userQueries.length} active user queries`);
      
      if (userQueries.length === 0) {
        console.log('📭 No active queries to process');
        return;
      }
      
      // Group queries by user_id
      const queriesByUser = this.groupQueriesByUser(userQueries);
      console.log(`👥 Processing queries for ${queriesByUser.size} users`);
      
      // Convert to array for batching
      const userEntries = Array.from(queriesByUser.entries());
      
      // Configure parallel processing
      const BATCH_SIZE = 3;
      console.log(`⚡ Processing users in parallel batches of ${BATCH_SIZE}`);
      
      let totalNewProperties = 0;
      
      // Process users in batches
      for (let i = 0; i < userEntries.length; i += BATCH_SIZE) {
        const batch = userEntries.slice(i, i + BATCH_SIZE);
        const batchNumber = Math.floor(i / BATCH_SIZE) + 1;
        const totalBatches = Math.ceil(userEntries.length / BATCH_SIZE);
        
        console.log(`\n🔄 Processing batch ${batchNumber}/${totalBatches} (${batch.length} users)`);
        
        // Process this batch in parallel
        const batchResults = await Promise.all(
          batch.map(([userId, queries]) => this.processUserQueries(userId, queries))
        );
        
        // Sum up new properties from this batch
        const batchNewProperties = batchResults.reduce((sum, result) => sum + result, 0);
        totalNewProperties += batchNewProperties;
        
        console.log(`✅ Batch ${batchNumber} completed: ${batchNewProperties} new properties found`);
        
        // Small delay between batches to be respectful to Rightmove
        if (i + BATCH_SIZE < userEntries.length) {
          console.log('⏱️ Brief pause between batches...');
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
      
      console.log(`\n✅ Completed processing all queries. Total new properties: ${totalNewProperties}`);
      
    } catch (error) {
      console.error('❌ Error processing user queries:', error);
    }
  }

  private async processQuery(query: UserQuery): Promise<{ newCount: number; errors: string[] }> {
    try {
      // Build search options, only including non-null parameters
      const searchOptions: SearchOptions = {
        searchType: 'RENT', // Default to rent for now
        locationIdentifier: query.location_id,
        getAllPages: false,
        quiet: true // Keep quiet for grouped processing
      };

      // Only add parameters that have values
      if (query.min_price) searchOptions.minPrice = query.min_price;
      if (query.max_price) searchOptions.maxPrice = query.max_price;
      if (query.min_bedrooms) searchOptions.minBedrooms = query.min_bedrooms;
      if (query.max_bedrooms) searchOptions.maxBedrooms = query.max_bedrooms;
      if (query.min_bathrooms) searchOptions.minBathrooms = query.min_bathrooms;
      if (query.max_bathrooms) searchOptions.maxBathrooms = query.max_bathrooms;
      if (query.furnish_type) searchOptions.furnishTypes = query.furnish_type as any;
      if (query.radius) searchOptions.radius = query.radius;
      
      // Get properties for this query
      const results = await this.scraper.searchProperties(searchOptions);
      console.log(`    📊 Found ${results.properties.length} properties`);
      
      // Limit to max properties per query
      let finalProperties = results.properties.slice(0, config.maxHDPropertiesPerQuery);
      
      // Enhance properties with HD images if enabled
      if (config.enableHDImages) {
        const propertiesWithHD = await this.scraper.getPropertiesWithHDImages(finalProperties, true);
        finalProperties = propertiesWithHD;
      }
      
      // Process properties for this specific query
      const processResult = await this.supabase.processPropertiesForQuery(query, finalProperties);
      
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
}

// Main execution
async function main() {
  console.log('Processing all user queries from Supabase database...');
  const monitor = new PropertyMonitor();
  await monitor.run();
}

// Run if this file is executed directly
if (require.main === module) {
  main();
}