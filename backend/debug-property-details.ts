#!/usr/bin/env tsx

import RightmoveScraper from './src/rightmove-scraper';

async function debugPropertyDetails() {
  const scraper = new RightmoveScraper();
  const propertyId = 164589905;
  
  console.log(`🔍 Debugging property details for ${propertyId}...`);
  
  try {
    // Use the private fetchPage method to get raw HTML
    const url = `https://www.rightmove.co.uk/properties/${propertyId}`;
    console.log(`Fetching: ${url}`);
    
    // Access the private method using bracket notation
    const response = await (scraper as any).fetchPage(url);
    
    console.log(`Status: ${response.statusCode}`);
    console.log(`Content length: ${response.data.length}`);
    
    // Look for __NEXT_DATA__ in the response
    const nextDataMatch = response.data.match(/<script id="__NEXT_DATA__" type="application\/json">(.*?)<\/script>/s);
    
    if (nextDataMatch) {
      console.log('✅ Found __NEXT_DATA__ script');
      
      try {
        const nextData = JSON.parse(nextDataMatch[1]);
        console.log('✅ Successfully parsed __NEXT_DATA__');
        console.log('Top level keys:', Object.keys(nextData));
        
        if (nextData.props) {
          console.log('Props keys:', Object.keys(nextData.props));
          
          if (nextData.props.pageProps) {
            console.log('PageProps keys:', Object.keys(nextData.props.pageProps));
            
            // Look for images in various locations
            const pageProps = nextData.props.pageProps;
            
            if (pageProps.propertyImages) {
              console.log(`✅ Found propertyImages: ${pageProps.propertyImages.length} images`);
              console.log('First image:', pageProps.propertyImages[0]);
            }
            
            if (pageProps.images) {
              console.log(`✅ Found images: ${pageProps.images.length} images`);
            }
            
            if (pageProps.propertyData && pageProps.propertyData.images) {
              console.log(`✅ Found propertyData.images: ${pageProps.propertyData.images.length} images`);
            }
            
            // Print all keys that might contain images
            Object.keys(pageProps).forEach(key => {
              if (key.toLowerCase().includes('image') || key.toLowerCase().includes('photo')) {
                console.log(`🖼️  Found image-related key: ${key}`);
              }
            });
          }
        }
        
      } catch (parseError) {
        console.error('❌ Failed to parse __NEXT_DATA__:', parseError);
        console.log('First 1000 chars of __NEXT_DATA__:', nextDataMatch[1].substring(0, 1000));
      }
    } else {
      console.log('❌ No __NEXT_DATA__ script found');
      
      // Look for other script tags that might contain image data
      const scriptMatches = response.data.match(/<script[^>]*>(.*?)<\/script>/gs);
      if (scriptMatches) {
        console.log(`Found ${scriptMatches.length} script tags`);
        
        scriptMatches.forEach((script, i) => {
          if (script.includes('propertyImages') || script.includes('media.rightmove.co.uk')) {
            console.log(`Script ${i} contains image data (length: ${script.length})`);
          }
        });
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

debugPropertyDetails();