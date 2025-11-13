// Configuration settings for the property monitor

export const config = {
  // Enable HD image fetching (set to false for faster scraping with thumbnails)
  enableHDImages: true,

  // Number of NEW properties to enhance with HD images per query
  // Sweet spot: 7 properties provides value without overwhelming users
  maxHDPropertiesPerQuery: 7,

  // Number of pages to scrape from Rightmove (24 properties per page)
  // 2 pages = 48 properties to check for new ones
  maxPagesToScrape: 2,

  // Delay between HD image requests (milliseconds) - important for rate limiting
  hdImageDelay: 2000,

  // Maximum number of images to store per property
  maxImagesPerProperty: 20
};

export default config;