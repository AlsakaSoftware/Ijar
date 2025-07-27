# Rightmove Property Monitor

A TypeScript system that:
1. **Scrapes** property listings from Rightmove
2. **Monitors** for new properties hourly via GitHub Actions  
3. **Alerts** via Telegram when new properties match your criteria
4. **Calls** estate agents automatically using Bland.ai (optional)

## 🚀 Quick Setup (GitHub Actions)

### 1. Fork this repository

### 2. Set up Telegram Bot
1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Create bot: `/newbot`
3. Get your bot token
4. Message your bot, then visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
5. Find your chat ID in the response

### 3. Add GitHub Secrets
Go to your repo → Settings → Secrets and variables → Actions:

- `TELEGRAM_BOT_TOKEN`: Your bot token from BotFather
- `TELEGRAM_CHAT_ID`: Your chat ID from step 2

### 4. Configure Searches
Edit `searches.json` with your preferred locations and criteria:

```json
{
  "my-search": {
    "name": "My Search Name",
    "searchType": "RENT",
    "location": "canary wharf", 
    "maxPrice": 3000,
    "minBedrooms": 2,
    "maxBedrooms": 2
  }
}
```

### 5. Update Workflow
Edit `.github/workflows/property-monitor.yml` to match your search keys.

### 6. Push to GitHub
The system will automatically run every hour and send Telegram alerts for new properties!

## 🏠 Available Locations
- `canary wharf`
- `london bridge`
- `canning town`
- `london`
- `manchester` 
- `birmingham`

## 💻 Local Development

### Setup
```bash
npm install
cp .env.example .env
# Add your Telegram bot credentials to .env
```

### Run Single Search
```bash
npm run monitor canary-wharf-2bed
```

### Test All Searches
```bash
npm run monitor canary-wharf-2bed
npm run monitor london-bridge-studio
npm run monitor canning-town-1bed
```

## 🔧 How It Works

1. **GitHub Actions runs hourly** (different times for each search)
2. **Scrapes Rightmove** with your search criteria  
3. **Compares** against previously found properties
4. **Sends Telegram alerts** for new properties only
5. **Commits tracking data** back to the repo

## 📱 Telegram Alert Format

```
🏠 2 New Property Alerts
📍 Canary Wharf 2 Bed

1. Flat 2, Landmark East Tower, Canary Wharf
💰 £3,200 pcm
🛏️ 2 bed | 🚿 2 bath
🔗 https://www.rightmove.co.uk/properties/123456

2. Apartment 15, Pan Peninsula East, Canary Wharf  
💰 £3,000 pcm
🛏️ 2 bed | 🚿 1 bath
🔗 https://www.rightmove.co.uk/properties/789012
```

## ☎️ Optional: Estate Agent Calling

If you want to automatically call agents, set up Bland.ai:

1. Sign up at https://bland.ai
2. Add `BLAND_API_KEY` to GitHub Secrets
3. Use the calling endpoints (see original README sections below)

## API Endpoints

- `POST /search-properties` - Search for properties with filters
- `GET /locations` - Get available search locations
- `POST /call-properties` - Initiate calls for multiple properties
- `POST /webhook/bland` - Webhook endpoint for Bland.ai callbacks
- `GET /call-results` - Get all call results
- `GET /call-results/:callId` - Get specific call result
- `GET /health` - Health check

### Search Properties Example:
```bash
curl -X POST http://localhost:3000/search-properties \
  -H "Content-Type: application/json" \
  -d '{
    "searchType": "RENT",
    "location": "canary wharf",
    "maxPrice": 3000,
    "minBedrooms": 2,
    "getAllPages": false
  }'
```

## Call Results

Results are saved to `call-results/` directory and include:
- Full transcript
- AI-generated summary
- Extracted viewing slots
- Property availability status
- Call duration and recording URL

## Important Notes

1. **Phone Numbers**: The scraper doesn't extract agent phone numbers. You need to either:
   - Manually add them to the JSON file
   - Enhance the scraper to visit individual property pages

2. **Rate Limiting**: The server waits 5 seconds between calls to avoid overwhelming agents

3. **Webhook**: For local testing, use ngrok:
   ```bash
   ngrok http 3000
   ```
   Then update WEBHOOK_URL in your .env file

4. **Costs**: Bland.ai charges ~$0.09 per minute of calling

## Next Steps

1. Add database for persistent storage
2. Extract agent phone numbers automatically
3. Add email notifications for results
4. Build a UI for selecting properties
5. Add scheduling to run scraper periodically