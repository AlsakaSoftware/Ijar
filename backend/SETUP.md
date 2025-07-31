# Property Monitor Setup

## Prerequisites

1. **Node.js** (v18 or higher)
2. **Supabase Project** with database access
3. **Environment Variables** configured

## Installation

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your actual values
```

3. Set up Supabase database:
```bash
# Run the schema.sql in your Supabase SQL editor
cat supabase/schema.sql
```

## Required Environment Variables

```bash
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

**Note**: Use the **service role key**, not the anon key, as the backend needs admin access to write data.

## Running the Monitor

Monitor a specific search:
```bash
npm run monitor canary-wharf-3bed
```

Available searches (from `searches.json`):
- `canary-wharf-3bed`
- `london-bridge-3bed`
- `canning-town-3bed`
- `mile-end-3bed` 
- `stratford-east-village-3bed`

## What the Monitor Does

1. **Fetches properties** from Rightmove using the search configuration
2. **Enriches data** with transport information (tube stations, distances)
3. **Saves to Supabase** - new properties are inserted, existing ones updated
4. **Tracks progress** in JSON files for git history
5. **Cleans up** old properties (marks as inactive after 30 days)

## Database Schema

The monitor creates properties with all fields needed by the iOS app:

- Basic info: price, bedrooms, bathrooms, address, images
- Location: latitude, longitude, area
- Transport: nearest tube station, distance, all nearby stations
- Metadata: search source, dates, activity status

## Testing

Test a single property fetch:
```bash
npm run scrape
```

## Data Flow

```
Rightmove Search → Property Details → Transport Enrichment → Supabase Storage
```

Properties are automatically deduplicated by Rightmove ID and enriched with tube station data from the property detail pages.