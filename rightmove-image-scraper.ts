interface RightmoveImage {
  lowRes: string;
  mediumRes: string;
  highRes: string;
  original: string;
}

export class RightmoveImageScraper {
  /**
   * Converts a low-resolution Rightmove image URL to higher quality versions
   * Tests multiple common resolutions since not all are available for every image
   */
  static getHighQualityImages(lowResUrl: string): RightmoveImage | null {
    if (!lowResUrl.includes('rightmove.co.uk')) {
      return null;
    }

    // Extract the base URL without resolution
    const urlParts = lowResUrl.match(/(.+)_max_\d+x\d+(\.\w+)$/);
    if (!urlParts) {
      return null;
    }

    const baseUrl = urlParts[1];
    const extension = urlParts[2];

    return {
      lowRes: lowResUrl,
      mediumRes: `${baseUrl}_max_656x437${extension}`,
      highRes: `${baseUrl}_max_1024x683${extension}`,
      original: `${baseUrl}${extension}` // No resolution constraint
    };
  }

  /**
   * Tests multiple resolution options for a given image URL
   * Returns array of URLs to test (some may not exist)
   */
  static getAllPossibleResolutions(lowResUrl: string): string[] {
    const urlParts = lowResUrl.match(/(.+)_max_\d+x\d+(\.\w+)$/);
    if (!urlParts) {
      return [lowResUrl];
    }

    const baseUrl = urlParts[1];
    const extension = urlParts[2];

    // Common resolutions found on Rightmove
    const resolutions = [
      '_max_296x197',  // Small thumbnail
      '_max_476x317',  // List view
      '_max_656x437',  // Medium
      '_max_768x512',  // Large
      '_max_1024x683', // Extra large
      '_max_1536x1025', // Very large
      ''               // Original (no resolution limit)
    ];

    return resolutions.map(res => `${baseUrl}${res}${extension}`);
  }

  /**
   * Extracts property ID from a Rightmove URL
   */
  static extractPropertyId(url: string): string | null {
    const match = url.match(/properties\/(\d+)/);
    return match ? match[1] : null;
  }

  /**
   * Gets all image URLs for a property from the listing data
   */
  static async getPropertyImages(propertyId: string): Promise<RightmoveImage[]> {
    // Note: This would require actual API access or web scraping
    // For now, this is a placeholder showing the structure
    
    const images: RightmoveImage[] = [];
    
    // In a real implementation, you would:
    // 1. Fetch the property page
    // 2. Extract all image URLs from the gallery
    // 3. Convert each to high quality versions
    
    return images;
  }

  /**
   * Example usage
   */
  static example() {
    const lowResUrl = "https://media.rightmove.co.uk:443/dir/crop/10:9-16:9/56k/55101/164087969/55101_1332966_IMG_01_0000_max_476x317.jpeg";
    
    const highQualityVersions = this.getHighQualityImages(lowResUrl);
    
    if (highQualityVersions) {
      console.log("Low Resolution:", highQualityVersions.lowRes);
      console.log("Medium Resolution:", highQualityVersions.mediumRes);
      console.log("High Resolution:", highQualityVersions.highRes);
      console.log("Original:", highQualityVersions.original);
    }
  }
}

// Test the scraper
const testUrl = "https://media.rightmove.co.uk:443/dir/crop/10:9-16:9/56k/55101/164087969/55101_1332966_IMG_01_0000_max_476x317.jpeg";
const result = RightmoveImageScraper.getHighQualityImages(testUrl);
console.log(result);