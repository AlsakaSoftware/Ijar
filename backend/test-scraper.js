#!/usr/bin/env node

// Simple test script to check if scraping works without Supabase
const { RightmoveScraper } = require('./dist/rightmove-scraper.js');

async function testScraper() {
  console.log('🔍 Testing Rightmove scraper...');
  
  const scraper = new RightmoveScraper();
  
  try {
    // Test basic search
    const searchOptions = {
      searchType: 'RENT',
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
      console.log('\n🏠 First property:');
      console.log(`  ID: ${firstProperty.id}`);
      console.log(`  Address: ${firstProperty.displayAddress}`);
      console.log(`  Price: ${firstProperty.price?.displayPrices?.[0]?.displayPrice || 'N/A'}`);
      console.log(`  Bedrooms: ${firstProperty.bedrooms}`);
      console.log(`  Bathrooms: ${firstProperty.bathrooms}`);
      console.log(`  Images: ${firstProperty.numberOfImages || 0}`);
      console.log(`  Location: ${firstProperty.location?.latitude}, ${firstProperty.location?.longitude}`);
      
      // Test enrichment with transport data
      console.log('\n🚇 Testing transport enrichment...');
      try {
        const enriched = await scraper.getEnrichedProperty(firstProperty, false);
        
        console.log('📍 Enriched property:');
        console.log(`  Address: ${enriched.displayAddress}`);
        console.log(`  Transport description: ${enriched.transportDescription || 'None'}`);
        console.log(`  Nearby stations: ${enriched.nearbyStations?.length || 0}`);
        
        if (enriched.nearbyStations && enriched.nearbyStations.length > 0) {
          enriched.nearbyStations.forEach((station, i) => {
            console.log(`    ${i + 1}. ${station.name} (${station.distance} mi) - ${station.types.join(', ')}`);
          });
        }
        
      } catch (enrichError) {
        console.warn('⚠️ Transport enrichment failed:', enrichError.message);
      }
    }
    
    console.log('\n✅ Scraper test completed successfully!');
    
  } catch (error) {
    console.error('❌ Scraper test failed:', error.message);
    console.error(error.stack);
  }
}

testScraper();