# 🏠 Rightmove Property Monitor

**Get instant Telegram alerts for new properties!**

A TypeScript system that:
1. **Scrapes** property listings from Rightmove
2. **Monitors** for new properties hourly via GitHub Actions  
3. **Sends Telegram alerts** when new properties match your criteria
4. **Runs completely free** on GitHub Actions

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

## 🛠️ Manual Testing

### Local Testing
```bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Add your Telegram credentials

# Test a single search
npm run monitor canary-wharf-2bed
```

### Add New Searches
Edit `searches.json`:
```json
{
  "my-new-search": {
    "name": "My Custom Search",
    "searchType": "RENT",
    "location": "london bridge",
    "maxPrice": 2500,
    "minBedrooms": 1,
    "maxBedrooms": 2
  }
}
```

Then update `.github/workflows/property-monitor.yml` to include your new search.

## 📊 Features

✅ **Free hosting** on GitHub Actions  
✅ **Duplicate detection** - never get the same property twice  
✅ **Multiple searches** - monitor different areas/criteria  
✅ **Error handling** - gets notified if monitoring fails  
✅ **Rate limiting** - respects Rightmove's servers  
✅ **Rich notifications** - formatted property details  

## 🔧 Technical Details

- **Storage**: Property tracking data stored in git commits
- **Scheduling**: GitHub Actions cron jobs (hourly)
- **Deduplication**: Composite keys (property ID + address)
- **Rate limiting**: 1 second delays between requests
- **Error handling**: Telegram notifications for failures