#!/usr/bin/env tsx

import fs from 'fs';
import path from 'path';
import RightmoveScraper from './rightmove-scraper';
import { TelegramBot } from './telegram';
import { SearchOptions, RightmoveProperty } from './scraper-types';

interface SearchConfig {
  name: string;
  searchType: 'SALE' | 'RENT';
  locationId: string;
  maxPrice?: number;
  minPrice?: number;
  minBedrooms?: number;
  maxBedrooms?: number;
  minBathrooms?: number;
  maxBathrooms?: number;
  furnishTypes?: 'furnished' | 'unfurnished' | 'furnished_or_unfurnished';
  radius?: number;
  propertyTypes?: string;
}

interface StoredProperty {
  key: string;
  id: string;
  address: string;
  price: string;
  bedrooms: number;
  bathrooms: number;
  propertyUrl: string;
  firstSeen: string;
}

class PropertyMonitor {
  private scraper: RightmoveScraper;
  private telegram: TelegramBot;
  private searchName: string;
  private searchConfig: SearchConfig;
  private dataFile: string;

  constructor(searchName: string, searchConfig: SearchConfig) {
    this.scraper = new RightmoveScraper();
    this.searchName = searchName;
    this.searchConfig = searchConfig;
    this.dataFile = path.join(__dirname, '..', `sent-properties-${searchName}.json`);

    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;
    
    if (!botToken || !chatId) {
      throw new Error('TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID environment variables are required');
    }
    
    this.telegram = new TelegramBot(botToken, chatId);
  }

  private calculatePropertyScore(property: StoredProperty, originalProperty: RightmoveProperty): number {
    let score = 0;
    
    // Recency score (newer = higher score)
    const now = Date.now();
    const propertyDate = originalProperty.firstVisibleDate ? 
      new Date(originalProperty.firstVisibleDate).getTime() : now;
    const daysOld = (now - propertyDate) / (1000 * 60 * 60 * 24);
    
    // Give higher score for newer properties (max 50 points, decays over 7 days)
    const recencyScore = Math.max(0, 50 - (daysOld * 7));
    score += recencyScore;
    
    // Photo count score (more photos = higher score)
    const photoScore = Math.min(originalProperty.numberOfImages || 0, 20) * 2; // Max 40 points for 20+ photos
    score += photoScore;
    
    return score;
  }

  private rankProperties(newProperties: StoredProperty[], originalProperties: RightmoveProperty[]): StoredProperty[] {
    // Create a map for quick lookup of original properties
    const originalMap = new Map(originalProperties.map(p => [p.id.toString(), p]));
    
    // Calculate scores and sort
    const scoredProperties = newProperties.map(property => ({
      property,
      score: this.calculatePropertyScore(property, originalMap.get(property.id) || {} as RightmoveProperty)
    }));
    
    // Sort by score (highest first)
    scoredProperties.sort((a, b) => b.score - a.score);
    
    return scoredProperties.map(item => item.property);
  }

  private loadSentProperties(): StoredProperty[] {
    try {
      if (fs.existsSync(this.dataFile)) {
        return JSON.parse(fs.readFileSync(this.dataFile, 'utf8'));
      }
    } catch (error) {
      console.error(`Error loading sent properties for ${this.searchName}:`, error);
    }
    return [];
  }

  private saveSentProperties(properties: StoredProperty[]): void {
    try {
      fs.writeFileSync(this.dataFile, JSON.stringify(properties, null, 2));
    } catch (error) {
      console.error(`Error saving sent properties for ${this.searchName}:`, error);
    }
  }

  private async commitChanges(newPropertiesCount: number): Promise<void> {
    if (process.env.GITHUB_ACTIONS !== 'true') {
      console.log('Not in GitHub Actions, skipping git commit');
      return;
    }

    try {
      const { execSync } = require('child_process');
      
      // Debug: Check if PAT_TOKEN is available
      const token = process.env.PAT_TOKEN;
      if (!token) {
        console.error('❌ PAT_TOKEN not found in environment variables');
        return;
      }
      console.log('✅ PAT_TOKEN found, configuring git authentication');
      
      // Configure git with PAT_TOKEN authentication  
      execSync('git config user.name "Property Monitor Bot"');
      execSync('git config user.email "property-monitor@github-actions.local"');
      
      // Configure git to use PAT_TOKEN for authentication
      execSync(`git remote set-url origin https://x-access-token:${token}@github.com/AlsakaSoftware/Rightmove-node-scraper.git`);
      
      // Add the tracking file
      execSync(`git add ${this.dataFile}`);
      
      // Check if there are changes to commit
      try {
        execSync('git diff --staged --quiet');
        console.log('No changes to commit');
        return;
      } catch {
        // Changes exist, proceed with commit
      }
      
      // Commit changes
      const message = `🏠 Track ${newPropertiesCount} new properties for ${this.searchName}`;
      execSync(`git commit -m "${message}"`);
      
      // Push changes
      execSync('git push origin HEAD');
      
      console.log(`✅ Committed tracking data for ${newPropertiesCount} new properties`);
      
    } catch (error) {
      console.error('❌ Failed to commit changes:', error);
    }
  }

  private formatProperty(property: RightmoveProperty): StoredProperty {
    return {
      key: this.scraper.getPropertyKey(property),
      id: property.id.toString(),
      address: property.displayAddress,
      price: property.price?.displayPrices?.[0]?.displayPrice || 'Price on request',
      bedrooms: property.bedrooms || 0,
      bathrooms: property.bathrooms || 0,
      propertyUrl: property.propertyUrl,
      firstSeen: new Date().toISOString()
    };
  }

  async run(): Promise<void> {
    const timestamp = new Date().toLocaleString();
    console.log(`[${timestamp}] 🔍 Monitoring: ${this.searchConfig.name}`);
    
    try {
      // Build search options
      const searchOptions: SearchOptions = {
        searchType: this.searchConfig.searchType,
        locationIdentifier: this.searchConfig.locationId,
        minPrice: this.searchConfig.minPrice,
        maxPrice: this.searchConfig.maxPrice,
        minBedrooms: this.searchConfig.minBedrooms,
        maxBedrooms: this.searchConfig.maxBedrooms,
        minBathrooms: this.searchConfig.minBathrooms,
        maxBathrooms: this.searchConfig.maxBathrooms,
        furnishTypes: this.searchConfig.furnishTypes,
        radius: this.searchConfig.radius,
        propertyTypes: this.searchConfig.propertyTypes,
        getAllPages: false,
        quiet: true
      };

      // Get current properties (first page only)
      const results = await this.scraper.searchProperties(searchOptions);
      const currentProperties = results.properties.map(p => this.formatProperty(p));
      
      // Load previously sent properties
      const sentProperties = this.loadSentProperties();
      const sentKeys = new Set(sentProperties.map(p => p.key));
      
      // Find new properties
      const newProperties = currentProperties.filter(p => !sentKeys.has(p.key));
      
      if (newProperties.length > 0) {
        console.log(`🎉 Found ${newProperties.length} new properties for ${this.searchConfig.name}`);
        
        // Rank properties by recency and photo count
        const rankedProperties = this.rankProperties(newProperties, results.properties);
        
        // Take top 3 properties
        const propertiesToSend = rankedProperties.slice(0, 3);
        console.log(`📨 Sending top ${propertiesToSend.length} of ${newProperties.length} properties (ranked by recency + photos)`);
        
        // Send Telegram alert
        const message = TelegramBot.formatPropertyMessage(propertiesToSend, this.searchConfig.name);
        const success = await this.telegram.sendMessage(message);
        
        if (success) {
          console.log(`📧 Alert sent for ${propertiesToSend.length} properties`);
          
          // Update sent properties (only the ones we actually sent)
          const updatedSent = [...sentProperties, ...propertiesToSend];
          
          // Keep only last 1000 properties to prevent file from growing too large
          if (updatedSent.length > 1000) {
            updatedSent.splice(0, updatedSent.length - 1000);
          }
          
          this.saveSentProperties(updatedSent);
          
          // Commit changes to git (in GitHub Actions)
          await this.commitChanges(newProperties.length);
        } else {
          console.error('❌ Failed to send Telegram alert');
        }
        
      } else {
        console.log(`📭 No new properties for ${this.searchConfig.name}`);
      }
      
    } catch (error) {
      console.error(`❌ Error monitoring ${this.searchConfig.name}:`, error);
      
      // Send error notification
      try {
        await this.telegram.sendMessage(
          `⚠️ <b>Monitor Error</b>\n` +
          `Search: ${this.searchConfig.name}\n` +
          `Error: ${error instanceof Error ? error.message : 'Unknown error'}`
        );
      } catch (telegramError) {
        console.error('Failed to send error notification:', telegramError);
      }
    }
  }
}

// Main execution
async function main() {
  const searchKey = process.argv[2];
  
  if (!searchKey) {
    console.error('Usage: tsx src/monitor.ts <search-key>');
    console.error('Available searches: ');
    
    try {
      const searchesPath = path.join(__dirname, '..', 'searches.json');
      const searches = JSON.parse(fs.readFileSync(searchesPath, 'utf8'));
      Object.keys(searches).forEach(key => {
        console.error(`  - ${key}: ${searches[key].name}`);
      });
    } catch (error) {
      console.error('Error loading searches.json');
    }
    
    process.exit(1);
  }
  
  try {
    // Load search configuration
    const searchesPath = path.join(__dirname, '..', 'searches.json');
    const searches = JSON.parse(fs.readFileSync(searchesPath, 'utf8'));
    
    if (!searches[searchKey]) {
      console.error(`Unknown search key: ${searchKey}`);
      console.error('Available searches:', Object.keys(searches).join(', '));
      process.exit(1);
    }
    
    const searchConfig = searches[searchKey];
    
    // Run monitor
    const monitor = new PropertyMonitor(searchKey, searchConfig);
    await monitor.run();
    
  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (require.main === module) {
  main();
}