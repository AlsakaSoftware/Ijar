import fs from 'fs';
import path from 'path';
import RightmoveScraper from './rightmove-scraper';
import { SearchOptions } from './scraper-types';

async function scrapeAndPrepareProperties() {
  const scraper = new RightmoveScraper();
  
  console.log('Scraping properties...');
  
  try {
    const options: SearchOptions = {
      searchType: 'RENT',
      postcode: 'E14 6FT',
      maxPrice: 3500,
      minBedrooms: 2,
      getAllPages: false // Just first page for testing
    };

    // Validate options
    const validation = scraper.validateSearchOptions(options);
    if (!validation.isValid) {
      console.error('Invalid search options:', validation.errors);
      return;
    }

    const results = await scraper.searchProperties(options);
    
    console.log(`Found ${results.total} properties total`);
    console.log(`Retrieved ${results.properties.length} properties`);
    
    // Test what data we can extract
    console.log('\n=== TESTING DATA EXTRACTION ===');

    for (let i = 0; i < Math.min(3, results.properties.length); i++) {
      const property = results.properties[i];
      console.log(`\n--- Property ${i + 1} ---`);
      console.log('Address:', property.displayAddress);
      console.log('Price:', property.price?.displayPrices?.[0]?.displayPrice || 'Price on request');
      console.log('Property URL:', property.propertyUrl);
      console.log('Full Rightmove URL:', `https://www.rightmove.co.uk${property.propertyUrl}`);
      console.log('Agent Name:', property.customer?.brandTradingName || 'Not available');
      console.log('Agent Phone (direct):', property.customer?.contactTelephone || 'Not available');
      console.log('Branch Name:', property.customer?.branchDisplayName || 'Not available');

      // Log full property structure to see what agent data we have
      console.log('\nFull property object keys:', Object.keys(property));
      console.log('Customer info:', JSON.stringify((property as any).customer || (property as any).agent || (property as any).contactInfo, null, 2));

      // Test agent phone extraction
      console.log('Extracting agent phone...');
      try {
        const agentPhone = await scraper.extractAgentPhone(property.id);
        console.log('Agent Phone:', agentPhone || 'Not found');
      } catch (error) {
        console.log('Agent Phone Error:', error instanceof Error ? error.message : 'Unknown error');
      }
    }

    // Format properties for the calling API
    const formattedProperties = await Promise.all(
      results.properties.slice(0, 10).map(async (property) => {
        return {
          id: property.id.toString(),
          address: property.displayAddress,
          price: property.price?.displayPrices?.[0]?.displayPrice || 'Price on request',
          bedrooms: property.bedrooms || 0,
          bathrooms: property.bathrooms || 0,
          propertyUrl: property.propertyUrl,
          rightmoveUrl: `https://www.rightmove.co.uk${property.propertyUrl}`,
          rightmoveId: property.id.toString(),
          agentPhone: property.customer?.contactTelephone || undefined,
          agentName: property.customer?.brandTradingName || undefined,
          branchName: property.customer?.branchDisplayName || undefined
        };
      })
    );
    
    // Save to file
    const outputPath = path.join(__dirname, '..', 'properties-to-call.json');
    fs.writeFileSync(outputPath, JSON.stringify({
      timestamp: new Date().toISOString(),
      count: formattedProperties.length,
      properties: formattedProperties
    }, null, 2));
    
    console.log(`Saved ${formattedProperties.length} properties to ${outputPath}`);
    
    // Count properties with phone numbers
    const propertiesWithPhones = formattedProperties.filter(p => p.agentPhone);
    console.log(`\nProperties with phone numbers: ${propertiesWithPhones.length}/${formattedProperties.length}`);
    
    if (propertiesWithPhones.length > 0) {
      console.log('Ready to make calls! Run: npm run dev');
    } else {
      console.log('No phone numbers found. You may need to manually add them to the JSON file.');
    }
    
  } catch (error) {
    console.error('Error scraping properties:', error);
  }
}

// Run the scraper
scrapeAndPrepareProperties();