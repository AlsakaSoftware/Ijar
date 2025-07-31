#!/usr/bin/env tsx

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import RightmoveScraper from './rightmove-scraper';
import { SupabasePropertyClient, DatabaseProperty } from './supabase-client';
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
  id: string;
  address: string;
  price: string;
  bedrooms: number;
  bathrooms: number;
  propertyUrl: string;
  firstSeen: string;
  searchName: string;
}

interface PropertyDatabase {
  lastUpdated: string;
  properties: Record<string, StoredProperty>; // keyed by property ID
}

class PropertyMonitor {
  private scraper: RightmoveScraper;
  private supabase: SupabasePropertyClient;
  private searchName: string;
  private searchConfig: SearchConfig;
  private dataFile: string; // Keep for backward compatibility during transition

  constructor(searchName: string, searchConfig: SearchConfig) {
    this.scraper = new RightmoveScraper();
    this.supabase = new SupabasePropertyClient();
    this.searchName = searchName;
    this.searchConfig = searchConfig;
    this.dataFile = path.join(__dirname, '..', 'sent-properties.json');
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

  private loadPropertyDatabase(): PropertyDatabase {
    try {
      if (fs.existsSync(this.dataFile)) {
        return JSON.parse(fs.readFileSync(this.dataFile, 'utf8'));
      }
    } catch (error) {
      console.error(`Error loading property database:`, error);
    }
    return {
      lastUpdated: new Date().toISOString(),
      properties: {}
    };
  }

  private savePropertyDatabase(database: PropertyDatabase): void {
    try {
      database.lastUpdated = new Date().toISOString();
      fs.writeFileSync(this.dataFile, JSON.stringify(database, null, 2));
    } catch (error) {
      console.error(`Error saving property database:`, error);
    }
  }

  private async commitChanges(newPropertiesCount: number): Promise<void> {
    console.log('🔄 Starting commitChanges process...');
    console.log('📊 Environment check:');
    console.log('   - GITHUB_ACTIONS:', process.env.GITHUB_ACTIONS);
    console.log('   - Current working directory:', process.cwd());
    console.log('   - Tracking file path:', this.dataFile);
    
    if (process.env.GITHUB_ACTIONS !== 'true') {
      console.log('📝 Not in GitHub Actions environment, skipping git commit');
      return;
    }

    try {
      const { execSync } = require('child_process');
      
      // Debug: Check if tracking file exists and show its contents
      console.log('📁 Checking tracking file:');
      try {
        const fs = require('fs');
        if (fs.existsSync(this.dataFile)) {
          const fileSize = fs.statSync(this.dataFile).size;
          console.log(`   ✅ File exists: ${this.dataFile} (${fileSize} bytes)`);
          
          // Show first few lines of the file
          const content = fs.readFileSync(this.dataFile, 'utf8');
          const lines = content.split('\n').slice(0, 3);
          console.log('   📄 File preview:', lines.join(' '));
        } else {
          console.log(`   ❌ File does not exist: ${this.dataFile}`);
          return;
        }
      } catch (error) {
        console.log('   📁 Error checking file:', error);
        return;
      }
      
      // Configure git user (required for commits)
      console.log('⚙️ Configuring git user...');
      execSync('git config user.name "Property Monitor Bot"');
      execSync('git config user.email "property-monitor@github-actions.local"');
      console.log('   ✅ Git user configured');
      
      // Debug: Show current git status before any changes
      console.log('🔍 Initial git status:');
      try {
        const gitStatus = execSync('git status --porcelain', { encoding: 'utf8' });
        console.log('   Git status output:', gitStatus || 'Clean working directory');
      } catch (error) {
        console.log('   Git status error:', error);
      }
      
      // Add the tracking file
      console.log(`📁 Adding tracking file to git: ${this.dataFile}`);
      execSync(`git add ${this.dataFile}`);
      console.log('   ✅ File added to staging area');
      
      // Check if there are changes to commit
      console.log('🔍 Checking for staged changes...');
      try {
        execSync('git diff --staged --quiet');
        console.log('❌ No changes detected in staging area');
        
        // Additional debug: show what's actually staged
        try {
          const stagedFiles = execSync('git diff --staged --name-only', { encoding: 'utf8' });
          console.log('   Staged files:', stagedFiles || 'None');
        } catch (e) {
          console.log('   Error getting staged files:', e);
        }
        return;
      } catch {
        console.log('✅ Changes detected in staging area, proceeding with commit');
      }
      
      // Show what will be committed
      try {
        const diffStat = execSync('git diff --staged --stat', { encoding: 'utf8' });
        console.log('📊 Changes to be committed:');
        console.log(diffStat);
      } catch (error) {
        console.log('   Error getting diff stat:', error);
      }
      
      // Commit changes
      const message = `🏠 Track ${newPropertiesCount} new properties for ${this.searchName}`;
      console.log('📝 Creating commit with message:', message);
      execSync(`git commit -m "${message}"`);
      console.log('   ✅ Commit created successfully');
      
      // Show commit info
      try {
        const commitInfo = execSync('git log -1 --oneline', { encoding: 'utf8' });
        console.log('📋 Latest commit:', commitInfo.trim());
      } catch (error) {
        console.log('   Error getting commit info:', error);
      }
      
      // Push changes (using existing authentication from checkout)
      console.log('🚀 Pushing changes to remote...');
      try {
        const pushOutput = execSync('git push origin HEAD', { encoding: 'utf8', stdio: 'pipe' });
        console.log('✅ Push successful!');
        if (pushOutput) console.log('   Push output:', pushOutput);
      } catch (pushError: any) {
        console.error('❌ Push failed:');
        console.error('   Exit code:', pushError.status);
        console.error('   Stdout:', pushError.stdout?.toString());
        console.error('   Stderr:', pushError.stderr?.toString());
        throw pushError;
      }
      
      console.log(`🎉 Successfully committed and pushed tracking data for ${newPropertiesCount} new properties`);
      
    } catch (error) {
      console.error('❌ Failed to commit changes:', error);
      console.log('🔍 Error details:');
      if (error instanceof Error) {
        console.log('   Message:', error.message);
        console.log('   Stack:', error.stack);
      }
    }
  }

  private formatProperty(property: RightmoveProperty): StoredProperty {
    return {
      id: property.id.toString(),
      address: property.displayAddress,
      price: property.price?.displayPrices?.[0]?.displayPrice || 'Price on request',
      bedrooms: property.bedrooms || 0,
      bathrooms: property.bathrooms || 0,
      propertyUrl: property.propertyUrl,
      firstSeen: new Date().toISOString(),
      searchName: this.searchName
    };
  }



  // Save to JSON file for backward compatibility
  private async saveToJsonFile(properties: RightmoveProperty[]): Promise<void> {
    try {
      const storedProperties = properties.map(p => this.formatProperty(p));
      const database = this.loadPropertyDatabase();
      
      storedProperties.forEach(property => {
        database.properties[property.id] = property;
      });
      
      this.savePropertyDatabase(database);
    } catch (error) {
      console.error('Error saving to JSON file:', error);
    }
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
      console.log('🔍 Fetching properties from Rightmove...');
      const results = await this.scraper.searchProperties(searchOptions);
      console.log(`📊 Found ${results.properties.length} properties from search`);
      
      // Find new properties using Supabase
      const newProperties = await this.supabase.getNewProperties(results.properties);
      
      if (newProperties.length > 0) {
        console.log(`🎉 Found ${newProperties.length} new properties for ${this.searchConfig.name}`);
        
        // Rank properties by recency and photo count
        const rankedProperties = this.rankProperties(newProperties, results.properties);
        
        // Take top 3 properties to process
        const propertiesToSend = rankedProperties.slice(0, 3);
        console.log(`📨 Processing top ${propertiesToSend.length} of ${newProperties.length} properties (ranked by recency + photos)`);
        
        // Save properties to Supabase
        console.log('💾 Saving properties to Supabase...');
        const saveResult = await this.supabase.upsertProperties(propertiesToSend, this.searchName);
        console.log(`📝 Saved ${saveResult.count} properties to Supabase`);
        
        if (saveResult.errors.length > 0) {
          console.warn('⚠️ Some properties failed to save:', saveResult.errors);
        }
        
        console.log(`✅ Successfully processed ${propertiesToSend.length} new properties`);
        
        // Also save to JSON for backward compatibility and git tracking
        await this.saveToJsonFile(propertiesToSend);
        
        // Commit changes to git (in GitHub Actions)
        await this.commitChanges(propertiesToSend.length);
        
        // Cleanup old properties in Supabase
        const deactivatedCount = await this.supabase.deactivateOldProperties(this.searchName, 30);
        if (deactivatedCount > 0) {
          console.log(`🧹 Deactivated ${deactivatedCount} old properties (>30 days)`);
        }
        
      } else {
        console.log(`📭 No new properties for ${this.searchConfig.name}`);
      }
      
    } catch (error) {
      console.error(`❌ Error monitoring ${this.searchConfig.name}:`, error);
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