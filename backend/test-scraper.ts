#!/usr/bin/env tsx

// Simple test script to check if scraping works without Supabase
import RightmoveScraper from './src/rightmove-scraper';

async function testScraper() {
  console.log('🔍 Testing Rightmove scraper...');
  
  const scraper = new RightmoveScraper();
  
  try {
    // Test basic search
    const searchOptions = {
      searchType: 'RENT' as const,
      locationIdentifier: 'STATION%5E1724', // Canary Wharf
      maxPrice: 3500,
      minBedrooms: 3,
      getAllPages: false,
      quiet: false
    };

    console.log('📊 Searching properties...');
    const results = await scraper.searchProperties(searchOptions);
    
    console.log(`✅ Found ${results.total} total properties`);
    console.log(`📦 Retrieved ${results.properties.length} properties`);
    
    if (results.properties.length > 0) {
      const firstProperty = results.properties[0];
      
      console.log('\n🔍 FULL RAW PROPERTY DATA FROM RIGHTMOVE:');
      console.log('='.repeat(80));
      console.log(JSON.stringify(firstProperty, null, 2));
      console.log('='.repeat(80));
      
      // Also show a simplified view
      console.log('\n🏠 Simplified property view:');
      console.log(`  ID: ${firstProperty.id}`);
      console.log(`  Address: ${firstProperty.displayAddress}`);
      console.log(`  Price: ${firstProperty.price?.displayPrices?.[0]?.displayPrice || 'N/A'}`);
      console.log(`  Bedrooms: ${firstProperty.bedrooms}`);
      console.log(`  Bathrooms: ${firstProperty.bathrooms}`);
      console.log(`  Images: ${firstProperty.numberOfImages || 0}`);
      console.log(`  Location: ${firstProperty.location?.latitude}, ${firstProperty.location?.longitude}`);
      
      // Show first few images
      if (firstProperty.images && firstProperty.images.length > 0) {
        console.log(`  Image URLs (first 3):`);
        firstProperty.images.slice(0, 3).forEach((img, i) => {
          console.log(`    ${i + 1}. ${img.srcUrl || img.url}`);
        });
      }
    }
    
    console.log('\n✅ Scraper test completed successfully!');
    
  } catch (error) {
    console.error('❌ Scraper test failed:', error instanceof Error ? error.message : 'Unknown error');
    if (error instanceof Error) {
      console.error(error.stack);
    }
  }
}

testScraper();