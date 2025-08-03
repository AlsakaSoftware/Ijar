#!/usr/bin/env tsx

import 'dotenv/config';
import RightmoveScraper from './src/rightmove-scraper';
import { SupabasePropertyClient } from './src/supabase-client';
import { SearchOptions } from './src/scraper-types';

async function testSimplifiedHD() {
  console.log('🧪 Testing simplified HD image replacement...\n');
  
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

    // Test with first property
    const originalProperty = results.properties[0];
    
    console.log('📷 BEFORE Enhancement:');
    console.log(`   Property: ${originalProperty.displayAddress}`);
    console.log(`   Images count: ${originalProperty.images.length}`);
    console.log(`   Sample image: ${originalProperty.images[0]?.srcUrl || originalProperty.images[0]?.url}`);
    
    console.log('\n🖼️  Enhancing with HD images...');
    const enhancedProperty = await scraper.getPropertyWithHDImages(originalProperty, false);
    
    console.log('\n📷 AFTER Enhancement:');
    console.log(`   Property: ${enhancedProperty.displayAddress}`);
    console.log(`   Images count: ${enhancedProperty.images.length}`);
    console.log(`   Sample image: ${enhancedProperty.images[0]?.srcUrl || enhancedProperty.images[0]?.url}`);
    
    // Compare image quality
    const originalUrl = originalProperty.images[0]?.srcUrl || originalProperty.images[0]?.url;
    const hdUrl = enhancedProperty.images[0]?.srcUrl || enhancedProperty.images[0]?.url;
    
    console.log('\n📊 Quality Comparison:');
    console.log(`   BEFORE: ${originalUrl}`);
    console.log(`   AFTER:  ${hdUrl}`);
    
    const isUpgraded = hdUrl !== originalUrl && !hdUrl.includes('_max_');
    console.log(`   🎯 Upgraded to HD: ${isUpgraded ? '✅ YES' : '❌ NO'}`);
    
    console.log('\n💾 Testing database storage...');
    const storeResult = await supabase.upsertProperty(enhancedProperty);
    
    if (storeResult.success) {
      console.log('✅ Successfully stored property with HD images');
      console.log(`   Stored ${storeResult.property?.images.length} HD image URLs`);
      console.log(`   Sample stored URL: ${storeResult.property?.images[0]}`);
    } else {
      console.log('❌ Failed to store property:', storeResult.error);
    }
    
    console.log('\n🎉 Simplified HD replacement test completed!');
    console.log('\n✨ Benefits:');
    console.log('• No database schema changes needed');
    console.log('• Existing images field now contains HD URLs');
    console.log('• Your app will automatically get high-quality images');
    console.log('• Same API, better quality');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

testSimplifiedHD();