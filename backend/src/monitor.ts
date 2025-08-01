#!/usr/bin/env tsx

import 'dotenv/config';
import RightmoveScraper from './rightmove-scraper';
import { SupabasePropertyClient, UserQuery } from './supabase-client';
import { SearchOptions } from './scraper-types';

class PropertyMonitor {
  private scraper: RightmoveScraper;
  private supabase: SupabasePropertyClient;

  constructor() {
    this.scraper = new RightmoveScraper();
    this.supabase = new SupabasePropertyClient();
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
      
      let totalNewProperties = 0;
      
      // Process each query
      for (const query of userQueries) {
        console.log(`\n🔍 Processing query: ${query.name}`);
        
        try {
          // Build search options, only including non-null parameters
          const searchOptions: SearchOptions = {
            searchType: 'RENT', // Default to rent for now
            locationIdentifier: query.location_id,
            getAllPages: false,
            quiet: false // Enable logging to see what's happening
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

          console.log(`   🔧 Search params:`, {
            location: query.location_id,
            price: query.min_price ? `£${query.min_price}-${query.max_price || 'max'}` : 'any',
            beds: query.min_bedrooms ? `${query.min_bedrooms}-${query.max_bedrooms || 'max'}` : 'any',
            baths: query.min_bathrooms ? `${query.min_bathrooms}-${query.max_bathrooms || 'max'}` : 'any'
          });
          
          // Get properties for this query
          const results = await this.scraper.searchProperties(searchOptions);
          console.log(`   📊 Found ${results.properties.length} properties`);
          
          // Process properties for this specific query
          const processResult = await this.supabase.processPropertiesForQuery(query, results.properties);
          
          if (processResult.newCount > 0) {
            console.log(`   🎉 Added ${processResult.newCount} new properties for query: ${query.name}`);
            totalNewProperties += processResult.newCount;
          } else {
            console.log(`   📭 No new properties for query: ${query.name}`);
          }
          
          if (processResult.errors.length > 0) {
            console.warn(`   ⚠️ Some errors occurred:`, processResult.errors.slice(0, 3));
          }
          
        } catch (error) {
          console.error(`   ❌ Error processing query ${query.name}:`, error);
        }
      }
      
      console.log(`\n✅ Completed processing all queries. Total new properties: ${totalNewProperties}`);
      
    } catch (error) {
      console.error('❌ Error processing user queries:', error);
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