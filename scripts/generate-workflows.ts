import * as fs from 'fs';
import * as path from 'path';

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

type SearchesConfig = Record<string, SearchConfig>;

// Read searches configuration
const searchesPath = path.join(__dirname, '..', 'searches.json');
const searches: SearchesConfig = JSON.parse(fs.readFileSync(searchesPath, 'utf8'));

// Generate cron schedules - distribute throughout the hour
const searchKeys = Object.keys(searches);
const minuteInterval = Math.floor(60 / searchKeys.length);

const generateWorkflow = (): string => {
  const cronJobs = searchKeys.map((key, index) => {
    const minute = (index * minuteInterval) % 60;
    return `    - cron: '${minute} * * * *'   # ${searches[key].name} - ${minute} minutes past every hour`;
  }).join('\n');

  const searchOptions = searchKeys.map(key => `          - ${key}`).join('\n');

  const jobs = searchKeys.map((key, index) => {
    const minute = (index * minuteInterval) % 60;
    const jobName = key.replace(/-/g, '_');
    
    return `  monitor_${jobName}:
    if: github.event_name == 'schedule' && github.event.schedule == '${minute} * * * *' || (github.event_name == 'workflow_dispatch' && (github.event.inputs.search_key == 'all' || github.event.inputs.search_key == '${key}'))
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          token: \${{ secrets.PAT_TOKEN }}
          
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm install
        
      - name: Run ${searches[key].name} monitor
        run: npm run monitor ${key}
        env:
          TELEGRAM_BOT_TOKEN: \${{ secrets.TELEGRAM_BOT_TOKEN }}
          TELEGRAM_CHAT_ID: \${{ secrets.TELEGRAM_CHAT_ID }}
          PAT_TOKEN: \${{ secrets.PAT_TOKEN }}`;
  }).join('\n\n');

  return `name: Property Monitor

# Set permissions at workflow level
permissions:
  contents: write

on:
  schedule:
    # Run every hour at distributed intervals
${cronJobs}
  
  # Allow manual triggering for testing
  workflow_dispatch:
    inputs:
      search_key:
        description: 'Search key to run (or "all" for all searches)'
        required: true
        default: 'all'
        type: choice
        options:
          - all
${searchOptions}

jobs:
${jobs}
`;
};

// Generate and write the workflow
const workflowContent = generateWorkflow();
const workflowPath = path.join(__dirname, '..', '.github', 'workflows', 'property-monitor.yml');
fs.writeFileSync(workflowPath, workflowContent);

console.log('✅ Generated workflow for', searchKeys.length, 'searches');
console.log('📋 Searches:', searchKeys.join(', '));
console.log('⏱️  Schedule:');
searchKeys.forEach((key, index) => {
  const minute = (index * minuteInterval) % 60;
  console.log(`   - ${searches[key].name}: ${minute} minutes past every hour`);
});