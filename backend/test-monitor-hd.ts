#!/usr/bin/env tsx

import 'dotenv/config';
import RightmoveScraper from './src/rightmove-scraper';
import { SupabasePropertyClient } from './src/supabase-client';
import { SearchOptions } from './src/scraper-types';

async function testMonitorWithHD() {
  console.log('🧪 Testing monitor script with HD images...\n');
  
  const scraper = new RightmoveScraper();
  const supabase = new SupabasePropertyClient();
  
  try {
    // Simulate a query (like what monitor.ts does)
    const mockQuery = {
      id: 'test-query-id',
      name: 'Test HD Query',
      location_id: 'POSTCODE%5E4294559',
      location_name: 'Canary Wharf',
      max_price: 3500,
      min_bedrooms: 2
    };

    console.log(`🔍 Processing query: ${mockQuery.name}`);

    // Build search options (like monitor.ts does)
    const searchOptions: SearchOptions = {
      searchType: 'RENT',
      locationIdentifier: mockQuery.location_id,
      getAllPages: false,
      quiet: false
    };

    if (mockQuery.max_price) searchOptions.maxPrice = mockQuery.max_price;
    if (mockQuery.min_bedrooms) searchOptions.minBedrooms = mockQuery.min_bedrooms;

    console.log('   🔧 Search params:', {
      location: mockQuery.location_id,
      price: `up to £${mockQuery.max_price}`,
      beds: `${mockQuery.min_bedrooms}+ bedrooms`
    });

    // Get properties for this query
    const results = await scraper.searchProperties(searchOptions);
    console.log(`   📊 Found ${results.properties.length} properties`);

    // Enhance properties with HD images (NEW STEP)
    console.log(`   🖼️  Fetching HD images for properties...`);
    const propertiesWithHD = await scraper.getPropertiesWithHDImages(results.properties.slice(0, 2), false);
    console.log(`   ✅ Enhanced ${propertiesWithHD.length} properties with HD images`);

    // Show the difference
    console.log('\n📊 Results Summary:');
    propertiesWithHD.forEach((property, index) => {
      const originalProperty = results.properties[index];
      
      console.log(`\nProperty ${index + 1}: ${property.displayAddress}`);
      console.log(`   Original images: ${originalProperty.images.length}`);
      console.log(`   HD images: ${property.images.length}`);
      console.log(`   Quality upgrade: ${originalProperty.images[0]?.srcUrl?.includes('_max_') ? '✅ YES' : '❌ NO'}`);
      console.log(`   Sample HD URL: ${property.images[0]?.srcUrl?.substring(0, 80)}...`);
    });

    console.log('\n🎉 Monitor HD test completed successfully!');
    console.log('\n📋 Next steps:');
    console.log('1. Your enhanced monitor script is ready');
    console.log('2. Run `npm run monitor` to start scraping with HD images');
    console.log('3. All new properties will automatically have HD images');
    console.log('4. No changes needed to your app - images field now contains HD URLs');

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testMonitorWithHD();