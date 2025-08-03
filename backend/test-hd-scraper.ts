#!/usr/bin/env tsx

import RightmoveScraper from './src/rightmove-scraper';
import { SearchOptions } from './src/scraper-types';

async function testHDImageScraping() {
  const scraper = new RightmoveScraper();
  
  console.log('🧪 Testing HD image scraping functionality...\n');
  
  try {
    // Test with a small search
    const options: SearchOptions = {
      searchType: 'RENT',
      locationIdentifier: 'POSTCODE%5E4294559', // E14 6FT - Canary Wharf
      maxPrice: 3500,
      minBedrooms: 2,
      getAllPages: false,
      quiet: false
    };

    console.log('🔍 Searching for properties...');
    const results = await scraper.searchProperties(options);
    console.log(`✅ Found ${results.properties.length} properties\n`);
    
    if (results.properties.length === 0) {
      console.log('❌ No properties found to test with');
      return;
    }

    // Test with just the first property
    const testProperty = results.properties[0];
    console.log(`🏠 Testing with property: ${testProperty.displayAddress}`);
    console.log(`   Property ID: ${testProperty.id}`);
    console.log(`   Current images: ${testProperty.images.length}`);
    
    // Show current thumbnail images
    console.log('\n📷 Current thumbnail images:');
    testProperty.images.slice(0, 3).forEach((img, i) => {
      console.log(`   ${i + 1}. ${img.srcUrl || img.url}`);
    });

    console.log('\n🖼️  Fetching HD images...');
    
    // Test HD image extraction
    const hdImages = await scraper.getHighQualityImages(testProperty.id);
    
    if (hdImages.length > 0) {
      console.log(`\n✅ Successfully extracted ${hdImages.length} HD images:`);
      hdImages.slice(0, 5).forEach((url, i) => {
        console.log(`   ${i + 1}. ${url}`);
      });
      
      // Test the enhanced property method
      console.log('\n🔄 Testing property enhancement...');
      const enhancedProperty = await scraper.getPropertyWithHDImages(testProperty);
      
      if (enhancedProperty.hdImages && enhancedProperty.hdImages.length > 0) {
        console.log(`✅ Property enhanced successfully with ${enhancedProperty.hdImages.length} HD images`);
        console.log(`   Original images: ${testProperty.images.length}`);
        console.log(`   HD images: ${enhancedProperty.hdImages.length}`);
      } else {
        console.log('⚠️  Property enhancement failed');
      }
      
    } else {
      console.log('❌ No HD images found');
      
      // Try to get property details to debug
      console.log('\n🔍 Debugging: Checking property details structure...');
      try {
        const details = await scraper.getPropertyDetails(testProperty.id);
        console.log('Available detail keys:', Object.keys(details));
        
        if (details.propertyImages) {
          console.log(`Found propertyImages array with ${details.propertyImages.length} items`);
        }
        if (details.images) {
          console.log(`Found images array with ${details.images.length} items`);
        }
      } catch (error) {
        console.log('Failed to get property details:', error);
      }
    }

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run the test
testHDImageScraping();