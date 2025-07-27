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
      location: 'canary wharf',
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
    
    // Format properties for the calling API
    const formattedProperties = await Promise.all(
      results.properties.slice(0, 10).map(async (property) => {
        // Try to extract agent phone number
        const agentPhone = await scraper.extractAgentPhone(property.id);
        
        return {
          id: property.id.toString(),
          address: property.displayAddress,
          price: property.price?.displayPrices?.[0]?.displayPrice || 'Price on request',
          bedrooms: property.bedrooms || 0,
          bathrooms: property.bathrooms || 0,
          propertyUrl: property.propertyUrl,
          rightmoveId: property.id.toString(),
          agentPhone: agentPhone || undefined,
          agentName: property.brand?.brandTradingName || undefined
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