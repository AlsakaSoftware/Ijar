// Configuration settings for the property monitor

export const config = {
  // Enable HD image fetching (set to false for faster scraping with thumbnails)
  enableHDImages: true,

  // Number of NEW properties to enhance with HD images per query
  // Now that we filter duplicates before HD fetching, this is more efficient
  maxHDPropertiesPerQuery: 10,

  // Delay between HD image requests (milliseconds) - important for rate limiting
  hdImageDelay: 2000,

  // Maximum number of images to store per property
  maxImagesPerProperty: 20
};

export default config;