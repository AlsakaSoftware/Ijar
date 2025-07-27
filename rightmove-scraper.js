const https = require('https');
const zlib = require('zlib');
const fs = require('fs');

class RightmoveScraper {
  constructor() {
    this.baseHeaders = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1'
    };
    
    this.locationMap = {
      'canary wharf': { 
        id: 'STATION%5E1724', 
        name: 'Canary+Wharf+Station',
        params: '&useLocationIdentifier=true&radius=1.0&propertyTypes=flat&_includeLetAgreed=on'
      },
      'london': { 
        id: 'REGION%5E87490', 
        name: 'London',
        params: ''
      },
      'canning town': { 
        id: 'REGION%5E70412', 
        name: 'Canning+Town%2C+East+London',
        params: '&useLocationIdentifier=true&radius=0.0&_includeLetAgreed=on'
      },
      'london bridge': { 
        id: 'STATION%5E5792', 
        name: 'London+Bridge',
        params: '&useLocationIdentifier=true&radius=0.5&_includeLetAgreed=on'
      }
    };
  }

  async fetchPage(url) {
    return new Promise((resolve, reject) => {
      const req = https.get(url, { headers: this.baseHeaders }, (res) => {
        let chunks = [];
        
        res.on('data', (chunk) => {
          chunks.push(chunk);
        });
        
        res.on('end', () => {
          let data = Buffer.concat(chunks);
          
          // Handle compression
          if (res.headers['content-encoding'] === 'gzip') {
            data = zlib.gunzipSync(data);
          } else if (res.headers['content-encoding'] === 'br') {
            data = zlib.brotliDecompressSync(data);
          }
          
          resolve({
            statusCode: res.statusCode,
            data: data.toString(),
            headers: res.headers
          });
        });
      });

      req.on('error', reject);
    });
  }

  extractNextData(html) {
    const nextDataMatch = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/s);
    if (nextDataMatch) {
      try {
        return JSON.parse(nextDataMatch[1]);
      } catch (e) {
        console.error('Error parsing __NEXT_DATA__:', e.message);
        return null;
      }
    }
    return null;
  }

  async searchProperties(options = {}) {
    const {
      searchType = 'RENT',
      locationIdentifier,
      location = null,
      minPrice,
      maxPrice,
      minBedrooms,
      maxBedrooms,
      getAllPages = false
    } = options;

    const baseUrl = searchType === 'RENT' ? 
      'https://www.rightmove.co.uk/property-to-rent/find.html' : 
      'https://www.rightmove.co.uk/property-for-sale/find.html';

    let allProperties = [];
    let index = 0;
    let totalProperties = 0;

    // Resolve location to identifier
    let actualLocationId = locationIdentifier;
    let extraParams = '';
    
    if (location) {
      const locationKey = location.toLowerCase();
      if (this.locationMap[locationKey]) {
        actualLocationId = this.locationMap[locationKey].id;
        extraParams = this.locationMap[locationKey].params;
        if (this.locationMap[locationKey].name !== location) {
          extraParams += `&searchLocation=${this.locationMap[locationKey].name}`;
        }
      } else {
        console.log(`Warning: Unknown location "${location}", using default London`);
      }
    }

    do {
      let url = `${baseUrl}?searchType=${searchType}&locationIdentifier=${actualLocationId}&index=${index}`;
      url += extraParams;
      
      if (minPrice) url += `&minPrice=${minPrice}`;
      if (maxPrice) url += `&maxPrice=${maxPrice}`;
      if (minBedrooms) url += `&minBedrooms=${minBedrooms}`;
      if (maxBedrooms) url += `&maxBedrooms=${maxBedrooms}`;

      console.log(`Fetching page ${Math.floor(index/24) + 1}: ${url}`);
      
      const response = await this.fetchPage(url);
      
      if (response.statusCode !== 200) {
        throw new Error(`HTTP ${response.statusCode}: ${response.data}`);
      }

      const nextData = this.extractNextData(response.data);
      
      if (nextData && nextData.props && nextData.props.pageProps && nextData.props.pageProps.searchResults) {
        const searchResults = nextData.props.pageProps.searchResults;
        const properties = searchResults.properties || [];
        
        allProperties = allProperties.concat(properties);
        totalProperties = searchResults.pagination?.total || 0;
        
        console.log(`Got ${properties.length} properties from this page`);
        
        if (!getAllPages || properties.length === 0) break;
        
        index += 24; // Rightmove shows 24 properties per page
        
        // Add delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 1000));
        
      } else {
        break;
      }
    } while (index < totalProperties);

    return {
      properties: allProperties,
      total: totalProperties,
      pages: Math.floor(index/24) + 1
    };
  }

  async getPropertyDetails(propertyId) {
    const url = `https://www.rightmove.co.uk/properties/${propertyId}`;
    
    console.log(`Fetching property details: ${url}`);
    
    const response = await this.fetchPage(url);
    
    if (response.statusCode !== 200) {
      throw new Error(`HTTP ${response.statusCode}: ${response.data}`);
    }

    const nextData = this.extractNextData(response.data);
    
    if (nextData && nextData.props && nextData.props.pageProps) {
      return nextData.props.pageProps;
    }
    
    throw new Error('Could not extract property details from response');
  }
}

// Example usage - now with simple location names!
async function main() {
  const scraper = new RightmoveScraper();
  
  try {
    console.log('Searching for properties in Canary Wharf...');
    
    // Search using simple location name - no more weird identifiers!
    const results = await scraper.searchProperties({
      searchType: 'RENT',
      location: 'london bridge',
      maxPrice: 3500,
      minBedrooms: 3,
      getAllPages: true
    });
    
    console.log(`Found ${results.total} properties`);
    console.log(`Retrieved ${results.properties.length} properties`);
    
    console.log(`\nTop 10 Properties:`);
    
    const top10 = results.properties.slice(0, 10);
    
    top10.forEach((property, index) => {
      const price = property.price?.displayPrices?.[0]?.displayPrice || 'Price on request';
      console.log(`${index + 1}. ${property.displayAddress}`);
      console.log(`   ${property.bedrooms} bed, ${property.bathrooms} bath - ${price}`);
      console.log(`   ID: ${property.id}`);
      console.log(`   URL: https://www.rightmove.co.uk${property.propertyUrl}`);

      console.log('');
    });
    
    // Save results
    fs.writeFileSync('canary_wharf_listings.json', JSON.stringify(top10, null, 2));
    console.log('Saved properties to canary_wharf_listings.json');
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

if (require.main === module) {
  main();
}

module.exports = RightmoveScraper;