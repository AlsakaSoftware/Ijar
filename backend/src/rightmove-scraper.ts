import * as https from 'https';
import * as zlib from 'zlib';
import { 
  SearchOptions, 
  RightmoveProperty, 
  RightmoveStation,
  SearchResults, 
  ApiResponse, 
  NextData 
} from './scraper-types';

export class RightmoveScraper {
  private readonly baseHeaders: Record<string, string>;

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
  }

  private async fetchPage(url: string): Promise<ApiResponse> {
    return new Promise((resolve, reject) => {
      const req = https.get(url, { headers: this.baseHeaders }, (res) => {
        const chunks: Buffer[] = [];
        
        res.on('data', (chunk: Buffer) => {
          chunks.push(chunk);
        });
        
        res.on('end', () => {
          let data = Buffer.concat(chunks);
          
          // Handle compression
          try {
            if (res.headers['content-encoding'] === 'gzip') {
              data = zlib.gunzipSync(data);
            } else if (res.headers['content-encoding'] === 'br') {
              data = zlib.brotliDecompressSync(data);
            }
          } catch (error) {
            console.error('Decompression error:', error);
            return reject(new Error('Failed to decompress response'));
          }
          
          resolve({
            statusCode: res.statusCode || 0,
            data: data.toString(),
            headers: res.headers as Record<string, string>
          });
        });
      });

      req.on('error', (error) => {
        reject(new Error(`Request failed: ${error.message}`));
      });

      req.setTimeout(30000, () => {
        req.destroy();
        reject(new Error('Request timeout'));
      });
    });
  }

  private extractNextData(html: string): NextData | null {
    const nextDataMatch = html.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/s);
    if (nextDataMatch) {
      try {
        return JSON.parse(nextDataMatch[1]) as NextData;
      } catch (error) {
        console.error('Error parsing __NEXT_DATA__:', error instanceof Error ? error.message : 'Unknown error');
        return null;
      }
    }
    return null;
  }

  private buildSearchUrl(options: SearchOptions, index: number): string {
    const {
      searchType = 'SALE',
      locationIdentifier,
      location,
      minPrice,
      maxPrice,
      minBedrooms,
      maxBedrooms,
      minBathrooms,
      maxBathrooms,
      furnishTypes,
      radius,
      propertyTypes
    } = options;

    const baseUrl = searchType === 'RENT' ? 
      'https://www.rightmove.co.uk/property-to-rent/find.html' : 
      'https://www.rightmove.co.uk/property-for-sale/find.html';

    // Use provided location identifier or default to London
    const actualLocationId = locationIdentifier || 'REGION%5E87490';

    let url = `${baseUrl}?searchType=${searchType}&locationIdentifier=${actualLocationId}&index=${index}`;
    
    // Add search parameters
    if (minPrice) url += `&minPrice=${minPrice}`;
    if (maxPrice) url += `&maxPrice=${maxPrice}`;
    if (minBedrooms) url += `&minBedrooms=${minBedrooms}`;
    if (maxBedrooms) url += `&maxBedrooms=${maxBedrooms}`;
    if (minBathrooms) url += `&minBathrooms=${minBathrooms}`;
    if (maxBathrooms) url += `&maxBathrooms=${maxBathrooms}`;
    if (furnishTypes) url += `&furnishTypes=${furnishTypes}`;
    
    // Add optional parameters
    if (radius !== undefined) url += `&radius=${radius}`;
    if (propertyTypes) url += `&propertyTypes=${propertyTypes}`;
    
    // Always include let agreed
    url += '&includeLetAgreed=true';

    return url;
  }

  async searchProperties(options: SearchOptions = {}): Promise<SearchResults> {
    const { getAllPages = false, quiet = false } = options;
    let allProperties: RightmoveProperty[] = [];
    let index = 0;
    let totalProperties = 0;

    do {
      const url = this.buildSearchUrl(options, index);
      if (!quiet) console.log(`Fetching page ${Math.floor(index/24) + 1}: ${url}`);
      
      try {
        const response = await this.fetchPage(url);
        
        if (response.statusCode !== 200) {
          throw new Error(`HTTP ${response.statusCode}: ${response.data}`);
        }

        const nextData = this.extractNextData(response.data);
        
        if (nextData?.props?.pageProps?.searchResults) {
          const searchResults = nextData.props.pageProps.searchResults;
          const properties = searchResults.properties || [];
          
          allProperties = allProperties.concat(properties);
          totalProperties = searchResults.pagination?.total || 0;
          
          if (!quiet) console.log(`Got ${properties.length} properties from this page`);
          
          if (!getAllPages || properties.length === 0) break;
          
          index += 24; // Rightmove shows 24 properties per page
          
          // Add delay to avoid rate limiting
          await new Promise(resolve => setTimeout(resolve, 1000));
          
        } else {
          if (!quiet) console.warn('No search results found in response');
          break;
        }
      } catch (error) {
        if (!quiet) console.error(`Failed to fetch page ${Math.floor(index/24) + 1}:`, error);
        break;
      }
    } while (index < totalProperties);

    return {
      properties: allProperties,
      total: totalProperties,
      pages: Math.floor(index/24) + 1
    };
  }

  async getPropertyDetails(propertyId: string | number, quiet = false): Promise<any> {
    const url = `https://www.rightmove.co.uk/properties/${propertyId}`;
    
    if (!quiet) console.log(`Fetching property details: ${url}`);
    
    try {
      const response = await this.fetchPage(url);
      
      if (response.statusCode !== 200) {
        throw new Error(`HTTP ${response.statusCode}: ${response.data}`);
      }
      
      // If __NEXT_DATA__ fails, return the raw HTML for image extraction
      if (!quiet) console.log('No __NEXT_DATA__ found, using HTML extraction method');
      return {
        html: response.data,
        propertyId: propertyId
      };
      
    } catch (error) {
      console.error(`Failed to get property details for ${propertyId}:`, error);
      throw error;
    }
  }

  // Extract transport/station information from property details
  private extractTransportInfo(pageProps: any): { stations: RightmoveStation[], description?: string } {
    const stations: RightmoveStation[] = [];
    let transportDescription: string | undefined;

    try {
      // Look for stations in various locations in the response
      if (pageProps.stations && Array.isArray(pageProps.stations)) {
        pageProps.stations.forEach((station: any) => {
          if (station.name && station.distance !== undefined) {
            stations.push({
              name: station.name,
              types: station.types || [],
              distance: station.distance,
              unit: station.unit || 'miles'
            });
          }
        });
      }

      // Also check for transport info in property description
      const description = pageProps.propertyDetails?.description || 
                         pageProps.propertyData?.description ||
                         pageProps.description;
      
      if (description && typeof description === 'string') {
        // Extract transport mentions from description
        const transportKeywords = ['station', 'tube', 'underground', 'DLR', 'railway', 'transport'];
        if (transportKeywords.some(keyword => description.toLowerCase().includes(keyword))) {
          transportDescription = description;
        }
      }

      // Look in features/amenities for transport info
      const features = pageProps.propertyDetails?.features || 
                      pageProps.propertyData?.features ||
                      pageProps.features;
      
      if (features && Array.isArray(features)) {
        const transportFeatures = features.filter((feature: string) => 
          typeof feature === 'string' && 
          ['station', 'tube', 'underground', 'DLR', 'transport'].some(keyword => 
            feature.toLowerCase().includes(keyword)
          )
        );
        
        if (transportFeatures.length > 0 && !transportDescription) {
          transportDescription = transportFeatures.join('; ');
        }
      }

    } catch (error) {
      console.warn('Error extracting transport info:', error);
    }

    return { stations, description: transportDescription };
  }


  // Helper method to validate search options
  validateSearchOptions(options: SearchOptions): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (options.searchType && !['SALE', 'RENT'].includes(options.searchType)) {
      errors.push('searchType must be either "SALE" or "RENT"');
    }

    if (options.minPrice && options.maxPrice && options.minPrice > options.maxPrice) {
      errors.push('minPrice cannot be greater than maxPrice');
    }

    if (options.minBedrooms && options.maxBedrooms && options.minBedrooms > options.maxBedrooms) {
      errors.push('minBedrooms cannot be greater than maxBedrooms');
    }

    // Location validation removed - now handled in searches.json

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Method to extract agent phone from property details
  async extractAgentPhone(propertyId: string | number, quiet = false): Promise<string | null> {
    try {
      const details = await this.getPropertyDetails(propertyId, quiet);
      
      // Look for agent contact information in various places
      const agentPhone = details.agent?.phone || 
                        details.brand?.contactTelephone || 
                        details.contactTelephone;
      
      return agentPhone || null;
    } catch (error) {
      if (!quiet) console.error(`Failed to extract agent phone for property ${propertyId}:`, error);
      return null;
    }
  }

  // Get property with enriched transport/station information
  async getEnrichedProperty(property: RightmoveProperty, quiet = false): Promise<RightmoveProperty> {
    try {
      const details = await this.getPropertyDetails(property.id, quiet);
      const transportInfo = this.extractTransportInfo(details);
      
      return {
        ...property,
        nearbyStations: transportInfo.stations,
        transportDescription: transportInfo.description
      };
    } catch (error) {
      if (!quiet) console.warn(`Failed to enrich property ${property.id} with transport info:`, error);
      return property; // Return original property if enrichment fails
    }
  }

  // Get enriched properties for a list (with rate limiting)
  async getEnrichedProperties(properties: RightmoveProperty[], quiet = false): Promise<RightmoveProperty[]> {
    const enrichedProperties: RightmoveProperty[] = [];
    
    for (const property of properties) {
      const enriched = await this.getEnrichedProperty(property, quiet);
      enrichedProperties.push(enriched);
      
      // Add delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    
    return enrichedProperties;
  }

  // Extract high-definition images from property details
  async getHighQualityImages(propertyId: string | number, quiet = false): Promise<string[]> {
    try {
      const details = await this.getPropertyDetails(propertyId, quiet);
      return this.extractHDImagesFromDetails(details);
    } catch (error) {
      if (!quiet) console.warn(`Failed to get HD images for property ${propertyId}:`, error);
      return [];
    }
  }

  // Extract HD images from property details response
  private extractHDImagesFromDetails(details: any): string[] {
    const hdImages: string[] = [];
    const seenUrls = new Set<string>();
    const seenImageIds = new Set<string>(); // Track unique image IDs
    
    // Helper function to extract image ID from URL
    const getImageId = (url: string): string => {
      // Extract the unique image identifier (e.g., "55101_1332966_IMG_01_0000")
      const match = url.match(/(\d+_\d+_IMG_\d+_\d+)/);
      return match ? match[1] : url;
    };

    // Helper function to normalize URL for deduplication
    const normalizeUrl = (url: string): string => {
      return url
        .replace(/_max_\d+x\d+/, '') // Remove resolution constraints
        .replace(/\/dir\/crop\/[^/]+\//, '/dir/') // Remove crop constraints
        .replace(/\?[^#]*/, ''); // Remove query parameters
    };

    try {
      // Extract images from HTML
      if (hdImages.length === 0 && details.html) {
        console.log('Extracting images from HTML...');
        
        // Extract all Rightmove image URLs from HTML
        const imageMatches = details.html.match(/https:\/\/media\.rightmove\.co\.uk[^"'\s]+\.jpe?g/gi);
        
        if (imageMatches) {
          // Process each URL to get the original quality version
          imageMatches.forEach((url: string) => {
            // Skip brand logos and non-property images
            if (url.includes('brand_logo') || url.includes('/brand/')) {
              return;
            }
            
            // Only process property images (contain IMG_ identifier)
            if (url.includes('IMG_')) {
              const normalizedUrl = normalizeUrl(url);
              const imageId = getImageId(normalizedUrl);
              
              // Only add if we haven't seen this image ID before
              if (!seenImageIds.has(imageId) && !seenUrls.has(normalizedUrl)) {
                seenImageIds.add(imageId);
                seenUrls.add(normalizedUrl);
                hdImages.push(normalizedUrl);
              }
            }
          });
        }
      }

    } catch (error) {
      console.warn('Error extracting HD images:', error);
    }
    
    console.log(`Extracted ${hdImages.length} unique HD images`);
    return hdImages.slice(0, 20); // Limit to 20 images max
  }

  // Get property with HD images
  async getPropertyWithHDImages(property: RightmoveProperty, quiet = false): Promise<RightmoveProperty> {
    try {
      if (!quiet) console.log(`  🖼️  Fetching HD images for property ${property.id}`);
      
      const hdImages = await this.getHighQualityImages(property.id, quiet);
      
      if (hdImages.length > 0) {
        if (!quiet) console.log(`  ✅ Replaced with ${hdImages.length} HD images`);
        
        // Create HD image objects to replace thumbnails
        const hdImageObjects = hdImages.map((url, index) => ({
          srcUrl: url,
          url: url,
          caption: `Image ${index + 1}`
        }));

        // Replace the original images array with HD images
        return {
          ...property,
          images: hdImageObjects, // Replace thumbnails with HD images
          numberOfImages: hdImages.length // Update count
        };
      } else {
        if (!quiet) console.log(`  ⚠️  No HD images found, keeping thumbnails`);
        return property;
      }
    } catch (error) {
      if (!quiet) console.warn(`  ❌ Failed to get HD images for property ${property.id}:`, error);
      return property; // Return original property if HD fetch fails
    }
  }

  // Get multiple properties with HD images (with rate limiting)
  async getPropertiesWithHDImages(properties: RightmoveProperty[], quiet = false): Promise<RightmoveProperty[]> {
    const enrichedProperties: RightmoveProperty[] = [];
    
    if (!quiet) console.log(`\n🖼️  Fetching HD images for ${properties.length} properties...`);
    
    for (let i = 0; i < properties.length; i++) {
      const property = properties[i];
      if (!quiet) console.log(`\n📸 Processing property ${i + 1}/${properties.length}: ${property.displayAddress}`);
      
      const enriched = await this.getPropertyWithHDImages(property, quiet);
      enrichedProperties.push(enriched);
      
      // Add delay to avoid rate limiting (important for detail page requests)
      if (i < properties.length - 1) {
        if (!quiet) console.log(`  ⏱️  Waiting 2 seconds to avoid rate limiting...`);
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }
    
    if (!quiet) console.log(`\n✅ Completed HD image fetching for all properties`);
    return enrichedProperties;
  }

  // Helper method to generate unique property key for deduplication
  getPropertyKey(property: RightmoveProperty): string {
    return `${property.id}-${property.displayAddress.replace(/\s+/g, '-').toLowerCase()}`;
  }
}

// Example usage
async function example() {
  const scraper = new RightmoveScraper();
  
  try {
    console.log('Rightmove scraper initialized');
    
    const options: SearchOptions = {
      searchType: 'RENT',
      location: 'canary wharf',
      maxPrice: 3500,
      minBedrooms: 2,
      getAllPages: false
    };

    // Validate options
    const validation = scraper.validateSearchOptions(options);
    if (!validation.isValid) {
      console.error('Invalid search options:', validation.errors);
      return;
    }

    const results = await scraper.searchProperties(options);
    
    console.log(`Found ${results.total} properties`);
    console.log(`Retrieved ${results.properties.length} properties`);
    
    const top5 = results.properties.slice(0, 5);
    
    for (const property of top5) {
      const price = property.price?.displayPrices?.[0]?.displayPrice || 'Price on request';
      console.log(`${property.displayAddress} - ${price}`);
      console.log(`  ${property.bedrooms} bed, ${property.bathrooms} bath`);
      console.log(`  URL: https://www.rightmove.co.uk${property.propertyUrl}`);
      
      // Try to extract agent phone
      const agentPhone = await scraper.extractAgentPhone(property.id);
      if (agentPhone) {
        console.log(`  Agent phone: ${agentPhone}`);
      }
      console.log('');
    }
    
    // Save results
    fs.writeFileSync('typescript-listings.json', JSON.stringify(top5, null, 2));
    console.log('Saved properties to typescript-listings.json');
    
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : 'Unknown error');
  }
}

// Export the class
export default RightmoveScraper;

// Run example if this file is executed directly
if (require.main === module) {
  example();
}