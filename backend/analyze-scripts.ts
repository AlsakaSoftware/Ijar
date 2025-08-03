#!/usr/bin/env tsx

import RightmoveScraper from './src/rightmove-scraper';

async function analyzeImageScripts() {
  const scraper = new RightmoveScraper();
  const propertyId = 164589905;
  
  console.log(`🔍 Analyzing image scripts for property ${propertyId}...`);
  
  try {
    const url = `https://www.rightmove.co.uk/properties/${propertyId}`;
    const response = await (scraper as any).fetchPage(url);
    
    const scriptMatches = response.data.match(/<script[^>]*>(.*?)<\/script>/gs);
    
    if (scriptMatches) {
      scriptMatches.forEach((script, i) => {
        if (script.includes('propertyImages') || script.includes('media.rightmove.co.uk')) {
          console.log(`\n🔍 Script ${i} (length: ${script.length}):`);
          console.log('=' .repeat(50));
          
          // Extract and show relevant parts
          let content = script.replace(/<\/?script[^>]*>/g, '');
          
          // Look for JSON data
          try {
            // Try to find JSON objects
            const jsonMatches = content.match(/\{[^{}]*"propertyImages"[^{}]*\}/g);
            if (jsonMatches) {
              console.log('Found propertyImages JSON:', jsonMatches[0]);
            }
            
            // Look for image URLs
            const imageUrls = content.match(/https:\/\/media\.rightmove\.co\.uk[^"'\s]+\.jpe?g/gi);
            if (imageUrls) {
              console.log(`\nFound ${imageUrls.length} image URLs:`);
              imageUrls.slice(0, 5).forEach((url, idx) => {
                console.log(`  ${idx + 1}. ${url}`);
              });
              if (imageUrls.length > 5) {
                console.log(`  ... and ${imageUrls.length - 5} more`);
              }
            }
            
            // Look for window object assignments
            const windowMatches = content.match(/window\.[^=]*=\s*(\{.*?\});?/gs);
            if (windowMatches) {
              console.log(`\nFound ${windowMatches.length} window assignments`);
              windowMatches.forEach((match, idx) => {
                if (match.includes('propertyImages') || match.includes('media.rightmove')) {
                  console.log(`  Window assignment ${idx}: ${match.substring(0, 200)}...`);
                }
              });
            }
            
          } catch (error) {
            console.log('Error analyzing script content:', error);
          }
        }
      });
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

analyzeImageScripts();