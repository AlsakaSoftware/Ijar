#!/usr/bin/env tsx

import 'dotenv/config';
import RightmoveScraper from './src/rightmove-scraper';
import { SupabasePropertyClient } from './src/supabase-client';
import { SearchOptions } from './src/scraper-types';

async function testFullHDMonitor() {
  console.log('🧪 Testing full HD image monitoring workflow...\n');
  
  const scraper = new RightmoveScraper();
  const supabase = new SupabasePropertyClient();
  
  try {
    // Test search options
    const searchOptions: SearchOptions = {
      searchType: 'RENT',
      locationIdentifier: 'POSTCODE%5E4294559', // E14 6FT - Canary Wharf
      maxPrice: 3500,
      minBedrooms: 2,
      getAllPages: false,
      quiet: false
    };

    console.log('🔍 Step 1: Searching for properties...');
    const results = await scraper.searchProperties(searchOptions);
    console.log(`✅ Found ${results.properties.length} properties\n`);
    
    if (results.properties.length === 0) {
      console.log('❌ No properties found to test with');
      return;
    }

    // Take just 2 properties for testing
    const testProperties = results.properties.slice(0, 2);
    
    console.log('🖼️  Step 2: Enhancing properties with HD images...');
    const propertiesWithHD = await scraper.getPropertiesWithHDImages(testProperties, false);
    
    console.log('\n📊 Step 3: Comparing results...');
    propertiesWithHD.forEach((property, index) => {
      console.log(`\nProperty ${index + 1}: ${property.displayAddress}`);
      console.log(`  Original images: ${testProperties[index].images.length}`);
      console.log(`  HD images: ${property.hdImages?.length || 0}`);
      console.log(`  Price: ${property.price?.displayPrices?.[0]?.displayPrice}`);
      
      if (property.hdImages && property.hdImages.length > 0) {
        console.log(`  Sample HD image: ${property.hdImages[0]}`);
      }
    });

    console.log('\n💾 Step 4: Testing database storage...');
    
    // Test storing one property
    const testProperty = propertiesWithHD[0];
    const storeResult = await supabase.upsertProperty(testProperty);
    
    if (storeResult.success) {
      console.log('✅ Successfully stored property with HD images in database');
      console.log(`   Stored ${storeResult.property?.images_hd.length} HD images`);
    } else {
      console.log('❌ Failed to store property:', storeResult.error);
    }
    
    console.log('\n🎉 Test completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Run: npm run monitor to use enhanced scraping');
    console.log('2. Update your app to use images_hd column for high-quality images');
    console.log('3. Apply database schema changes to add images_hd column');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testFullHDMonitor();