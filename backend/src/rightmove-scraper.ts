import * as https from 'https';
import * as zlib from 'zlib';
import * as fs from 'fs';
import {
  SearchOptions,
  RightmoveProperty,
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
              data = Buffer.from(zlib.gunzipSync(data));
            } else if (res.headers['content-encoding'] === 'br') {
              data = Buffer.from(zlib.brotliDecompressSync(data));
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
      postcode,
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

    // Format postcode for URL (e.g., "E14 6FT" -> "E14-6FT")
    const formattedPostcode = postcode.replace(/\s+/g, '-');

    // Build direct postcode URL
    const baseUrl = searchType === 'RENT' ?
      `https://www.rightmove.co.uk/property-to-rent/${formattedPostcode}.html` :
      `https://www.rightmove.co.uk/property-for-sale/${formattedPostcode}.html`;

    let url = baseUrl;

    // Add index parameter if not first page
    if (index > 0) {
      url += `?index=${index}`;
    }

    const params = new URLSearchParams();

    // Add search parameters
    if (minPrice) params.append('minPrice', minPrice.toString());
    if (maxPrice) params.append('maxPrice', maxPrice.toString());
    if (minBedrooms !== undefined) params.append('minBedrooms', minBedrooms.toString());
    if (maxBedrooms !== undefined) params.append('maxBedrooms', maxBedrooms.toString());
    if (minBathrooms !== undefined) params.append('minBathrooms', minBathrooms.toString());
    if (maxBathrooms !== undefined) params.append('maxBathrooms', maxBathrooms.toString());
    if (furnishTypes) params.append('furnishTypes', furnishTypes);
    if (radius !== undefined) params.append('radius', radius.toString());
    if (propertyTypes) params.append('propertyTypes', propertyTypes);

    // Always include let agreed
    params.append('includeLetAgreed', 'true');

    // Append parameters to URL
    const paramString = params.toString();
    if (paramString) {
      url += (index > 0 ? '&' : '?') + paramString;
    }

    return url;
  }

  async searchProperties(options: SearchOptions): Promise<SearchResults> {
    const { getAllPages = false, maxPages, quiet = false } = options;
    let allProperties: RightmoveProperty[] = [];
    let index = 0;
    let totalProperties = 0;
    let pagesFetched = 0;
    let shouldContinue = true;

    while (shouldContinue) {
      const url = this.buildSearchUrl(options, index);
      if (!quiet) console.log(`Fetching page ${pagesFetched + 1}: ${url}`);

      try {
        const response = await this.fetchPage(url);

        if (response.statusCode === 404) {
          throw new Error(`Page not found (404) - Invalid search parameters or location identifier`);
        }

        if (response.statusCode !== 200) {
          throw new Error(`HTTP ${response.statusCode}: ${response.data}`);
        }

        const nextData = this.extractNextData(response.data);

        if (nextData?.props?.pageProps?.searchResults) {
          const searchResults = nextData.props.pageProps.searchResults;
          const properties = searchResults.properties || [];

          allProperties = allProperties.concat(properties);
          totalProperties = searchResults.pagination?.total || 0;
          pagesFetched++;

          if (!quiet) console.log(`Got ${properties.length} properties from this page (total available: ${totalProperties}, fetched so far: ${allProperties.length})`);

          // Stop if: no properties returned
          if (properties.length === 0) {
            shouldContinue = false;
            break;
          }

          // Stop if not getting all pages and no maxPages limit (single page mode)
          if (!getAllPages && !maxPages) {
            shouldContinue = false;
            break;
          }

          // Stop if reached maxPages limit
          if (maxPages && pagesFetched >= maxPages) {
            shouldContinue = false;
            break;
          }

          // Stop if getAllPages is true and we've fetched everything
          if (getAllPages && allProperties.length >= totalProperties) {
            shouldContinue = false;
            break;
          }

          index += 24; // Rightmove shows 24 properties per page

          // Add delay to avoid rate limiting (skip for last page)
          await new Promise(resolve => setTimeout(resolve, 1000));

        } else {
          if (!quiet) console.warn('No search results found in response');
          shouldContinue = false;
          break;
        }
      } catch (error) {
        if (!quiet) console.error(`Failed to fetch page ${pagesFetched + 1}:`, error);
        shouldContinue = false;
        break;
      }
    }

    return {
      properties: allProperties,
      total: totalProperties,
      pages: pagesFetched
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

  // Get property with enriched information
  async getEnrichedProperty(property: RightmoveProperty, quiet = false): Promise<RightmoveProperty> {
    try {
      const details = await this.getPropertyDetails(property.id, quiet);

      return {
        ...property
      };
    } catch (error) {
      if (!quiet) console.warn(`Failed to enrich property ${property.id}:`, error);
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

  // Extract comprehensive property details including HD images, floorplans, description, key features, etc.
  async getFullPropertyDetails(propertyId: string | number, quiet = false): Promise<any> {
    try {
      const details = await this.getPropertyDetails(propertyId, quiet);

      // Extract HD images
      const hdImages = this.extractHDImagesFromDetails(details);

      // Extract floorplan images
      const floorplanImages = this.extractFloorplanImagesFromDetails(details);

      // Extract property details from HTML
      const propertyDetails = this.extractPropertyDetailsFromHTML(details.html);

      return {
        propertyId,
        hdImages,
        floorplanImages,
        ...propertyDetails
      };
    } catch (error) {
      if (!quiet) console.warn(`Failed to get full property details for ${propertyId}:`, error);
      throw error;
    }
  }

  // Extract property details (description, key features, listing details) from HTML
  private extractPropertyDetailsFromHTML(html: string): any {
    const details: any = {
      description: null,
      keyFeatures: [],
      propertyType: null,
      floorArea: null,
      epcRating: null,
      councilTaxBand: null,
      tenure: null,
      listingDate: null,
      availableFrom: null
    };

    try {
      // Extract description - found in <div class="STw8udCxUaBUMfOOZu0iL _3nPVwR0HZYQah5tkVJHFh5"><div>...</div></div>
      const descMatch = html.match(/<div class="STw8udCxUaBUMfOOZu0iL _3nPVwR0HZYQah5tkVJHFh5">\s*<div>(.*?)<\/div>/is);
      if (descMatch) {
        details.description = descMatch[1]
          .replace(/<br\s*\/?>/gi, '\n') // Convert <br> to newlines
          .replace(/<[^>]+>/g, '') // Remove other HTML tags
          .replace(/\s+/g, ' ') // Normalize whitespace
          .replace(/\n\s+/g, '\n') // Clean up newlines
          .trim();
      }

      // Extract key features - found in <ul class="_1uI3IvdF5sIuBtRIvKrreQ"><li class="lIhZ24u1NHMa5Y6gDH90A">...</li></ul>
      const keyFeaturesMatch = html.match(/<ul class="_1uI3IvdF5sIuBtRIvKrreQ">(.*?)<\/ul>/is);
      if (keyFeaturesMatch) {
        const liMatches = keyFeaturesMatch[1].match(/<li class="lIhZ24u1NHMa5Y6gDH90A">(.*?)<\/li>/gis);
        if (liMatches) {
          details.keyFeatures = liMatches.map(li =>
            li.replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim()
          ).filter(f => f.length > 0);
        }
      }

      // Extract property type - found in <p class="_1hV1kqpVceE9m-QrX_hWDN  ">Apartment</p>
      const propTypeMatch = html.match(/<dt class="IXkFvLy8-4DdLI1TIYLgX"><span class="ZBWaPR-rIda6ikyKpB_E2">PROPERTY TYPE<\/span><\/dt>\s*<dd[^>]*>.*?<p class="_1hV1kqpVceE9m-QrX_hWDN[^"]*">([^<]+)<\/p>/is);
      if (propTypeMatch) {
        details.propertyType = propTypeMatch[1].trim();
      }

      // Extract floor area - found in SIZE section <p class="_1hV1kqpVceE9m-QrX_hWDN  ">616 sq ft</p>
      const floorAreaMatch = html.match(/<dt class="IXkFvLy8-4DdLI1TIYLgX"><span class="ZBWaPR-rIda6ikyKpB_E2">SIZE<\/span><\/dt>\s*<dd[^>]*>.*?<p class="_1hV1kqpVceE9m-QrX_hWDN[^"]*">([^<]+)<\/p>/is);
      if (floorAreaMatch) {
        details.floorArea = floorAreaMatch[1].trim();
      }

      // Extract EPC rating
      const epcMatch = html.match(/EPC rating[:\s]*([A-G])/i);
      if (epcMatch) {
        details.epcRating = epcMatch[1].toUpperCase();
      }

      // Extract council tax band - found in <dd class="_2zXKe70Gdypr_v9MUDoVCm">Band: E</dd>
      const councilTaxMatch = html.match(/<dt class="_17A0LehXZKxGHbPeiLQ1BI">COUNCIL TAX.*?<\/dt>\s*<dd class="_2zXKe70Gdypr_v9MUDoVCm">Band:\s*([A-H])<\/dd>/is);
      if (councilTaxMatch) {
        details.councilTaxBand = councilTaxMatch[1].toUpperCase();
      }

      // Extract tenure
      const tenureMatch = html.match(/Tenure[:\s]*(Freehold|Leasehold)/i);
      if (tenureMatch) {
        details.tenure = tenureMatch[1];
      }

      // Extract listing date (first visible date)
      const listingDateMatch = html.match(/added on[:\s]*(\d{1,2}(?:st|nd|rd|th)?\s+\w+\s+\d{4})/i);
      if (listingDateMatch) {
        details.listingDate = listingDateMatch[1];
      }

      // Extract available from date - found in <dt>Let available date: </dt><dd>15/12/2025</dd>
      const availableMatch = html.match(/<dt>Let available date:\s*<\/dt>\s*<dd>([^<]+)<\/dd>/i);
      if (availableMatch) {
        details.availableFrom = availableMatch[1].trim();
      }

    } catch (error) {
      console.warn('Error extracting property details from HTML:', error);
    }

    return details;
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
    const seenImageIds = new Set<string>(); // Track unique image IDs only
    
    // Helper function to extract image ID from URL
    const getImageId = (url: string): string => {
      // Extract the unique image identifier (e.g., "IMG_01" from "55101_1332966_IMG_01_0000")
      const match = url.match(/IMG_(\d+)/);
      return match ? match[1] : '';
    };

    // Helper function to get the highest quality version of an image URL
    const getHighQualityUrl = (url: string): string => {
      // Remove any size constraints, crop parameters, and query strings
      let cleanUrl = url
        .replace(/_max_\d+x\d+/, '') // Remove resolution constraints
        .replace(/\/dir\/crop\/[^/]+\//, '/dir/') // Remove crop constraints
        .replace(/\?[^#]*/, ''); // Remove query parameters
      
      // Prefer URLs without /dir/ prefix (they're typically the same image but shorter path)
      cleanUrl = cleanUrl.replace(/\/dir\//, '/');
      
      return cleanUrl;
    };

    try {
      // Extract images from HTML
      if (details.html) {
        console.log('Extracting images from HTML...');
        
        // Extract all Rightmove image URLs from HTML
        const imageMatches = details.html.match(/https:\/\/media\.rightmove\.co\.uk[^"'\s]+\.jpe?g/gi);
        
        if (imageMatches) {
          // Create a map to store the best version of each image
          const imageMap = new Map<string, string>();
          
          // Process each URL
          imageMatches.forEach((url: string) => {
            // Skip brand logos and non-property images
            if (url.includes('brand_logo') || url.includes('/brand/') || url.includes('_BP_')) {
              return;
            }
            
            // Only process property images (contain IMG_ identifier)
            if (url.includes('IMG_')) {
              const imageId = getImageId(url);
              
              if (imageId) {
                const highQualityUrl = getHighQualityUrl(url);
                
                // Store only if we haven't seen this image ID or if this is a better quality version
                // Prefer URLs without /dir/ (shorter paths are typically better)
                if (!imageMap.has(imageId)) {
                  imageMap.set(imageId, highQualityUrl);
                } else {
                  const existingUrl = imageMap.get(imageId)!;
                  // Prefer the URL without /dir/ path, or shorter URL if both have same path type
                  if (!highQualityUrl.includes('/dir/') && existingUrl.includes('/dir/')) {
                    imageMap.set(imageId, highQualityUrl);
                  } else if (highQualityUrl.length < existingUrl.length && 
                           highQualityUrl.includes('/dir/') === existingUrl.includes('/dir/')) {
                    imageMap.set(imageId, highQualityUrl);
                  }
                }
              }
            }
          });
          
          // Convert map to array, maintaining order
          const sortedEntries = Array.from(imageMap.entries()).sort((a, b) => {
            // Sort by image number (IMG_01, IMG_02, etc.)
            return parseInt(a[0]) - parseInt(b[0]);
          });
          
          sortedEntries.forEach(([_, url]) => {
            hdImages.push(url);
          });
        }
      }

    } catch (error) {
      console.warn('Error extracting HD images:', error);
    }
    
    console.log(`Extracted ${hdImages.length} unique HD images`);
    return hdImages.slice(0, 20); // Limit to 20 images max
  }

  // Extract floorplan images from property details response
  private extractFloorplanImagesFromDetails(details: any): string[] {
    const floorplanImages: string[] = [];
    const seenImageIds = new Set<string>(); // Track unique floorplan IDs

    // Helper function to extract floorplan ID from URL
    const getFloorplanId = (url: string): string => {
      // Extract the unique floorplan identifier (e.g., "FLP_00" from "229157_PRL250131_L_FLP_00_0000")
      const match = url.match(/FLP_(\d+)/);
      return match ? match[1] : '';
    };

    // Helper function to get the highest quality version of a floorplan URL
    const getHighQualityUrl = (url: string): string => {
      // Remove any size constraints and query strings
      let cleanUrl = url
        .replace(/_max_\d+x\d+/, '') // Remove resolution constraints
        .replace(/\/dir\/crop\/[^/]+\//, '/dir/') // Remove crop constraints
        .replace(/\?[^#]*/, ''); // Remove query parameters

      // Prefer URLs without /dir/ prefix
      cleanUrl = cleanUrl.replace(/\/dir\//, '/');

      return cleanUrl;
    };

    try {
      // Extract floorplans from HTML
      if (details.html) {
        console.log('Extracting floorplans from HTML...');

        // Extract all Rightmove floorplan URLs from HTML (look for _FLP_ pattern)
        const floorplanMatches = details.html.match(/https:\/\/media\.rightmove\.co\.uk[^"'\s]+FLP[^"'\s]+\.jpe?g/gi);

        if (floorplanMatches) {
          // Create a map to store the best version of each floorplan
          const floorplanMap = new Map<string, string>();

          // Process each URL
          floorplanMatches.forEach((url: string) => {
            // Only process floorplan images (contain FLP_ identifier)
            if (url.includes('FLP_')) {
              const floorplanId = getFloorplanId(url);

              if (floorplanId) {
                const highQualityUrl = getHighQualityUrl(url);

                // Store only if we haven't seen this floorplan ID or if this is a better quality version
                if (!floorplanMap.has(floorplanId)) {
                  floorplanMap.set(floorplanId, highQualityUrl);
                } else {
                  const existingUrl = floorplanMap.get(floorplanId)!;
                  // Prefer the URL without /dir/ path, or shorter URL if both have same path type
                  if (!highQualityUrl.includes('/dir/') && existingUrl.includes('/dir/')) {
                    floorplanMap.set(floorplanId, highQualityUrl);
                  } else if (highQualityUrl.length < existingUrl.length &&
                           highQualityUrl.includes('/dir/') === existingUrl.includes('/dir/')) {
                    floorplanMap.set(floorplanId, highQualityUrl);
                  }
                }
              }
            }
          });

          // Convert map to array, maintaining order
          const sortedEntries = Array.from(floorplanMap.entries()).sort((a, b) => {
            // Sort by floorplan number (FLP_00, FLP_01, etc.)
            return parseInt(a[0]) - parseInt(b[0]);
          });

          sortedEntries.forEach(([_, url]) => {
            floorplanImages.push(url);
          });
        }
      }

    } catch (error) {
      console.warn('Error extracting floorplan images:', error);
    }

    console.log(`Extracted ${floorplanImages.length} unique floorplan images`);
    return floorplanImages;
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
      postcode: 'E14 6FT',
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