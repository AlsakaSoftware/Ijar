# Push Notifications Setup

This document explains how to set up Apple Push Notifications (APNs) for the Ijar property monitoring system.

## Overview

The system sends push notifications to users when new properties are found for their search queries. Notifications are batched per user - if a user has multiple queries, they receive one notification with the total count of new properties found.

## Backend Setup

### 1. Database Setup

Run the SQL script to create the device_tokens table:

```sql
-- Run sql/device_tokens.sql in your Supabase database
```

### 2. APNs Configuration

You'll need either:

**Option A: P8 Auth Key (Recommended)**
- Download a p8 key from Apple Developer Console
- Add to environment variables:
  - `APN_AUTH_KEY`: Content of the p8 key file
  - `APN_KEY_ID`: Key ID from Apple Developer Console  
  - `APN_TEAM_ID`: Your Apple Developer Team ID

**Option B: Certificate Files**
- Generate push notification certificates
- Set file paths in environment variables:
  - `APN_CERT_PATH`: Path to certificate file
  - `APN_KEY_PATH`: Path to private key file
  - `APN_PASSPHRASE`: Optional passphrase

### 3. Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Required
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
APN_BUNDLE_ID=com.yourapp.ijar

# APNs authentication (choose one method)
APN_AUTH_KEY=your_p8_key_content
APN_KEY_ID=your_key_id
APN_TEAM_ID=your_team_id

# Environment
NODE_ENV=development  # or 'production' for production APNs
```

## iOS App Setup

### 1. Enable Push Notifications

In Xcode:
1. Select your app target
2. Go to "Signing & Capabilities"
3. Add "Push Notifications" capability

### 2. User Flow

1. User signs in with Apple ID
2. App requests notification permission
3. Device token is automatically registered with Supabase
4. When properties are found, user receives notification
5. Tapping notification opens the app

### 3. Notification Settings

Users can manage notifications in Profile > Push Notifications

## How It Works

### Notification Flow

1. **Monitor runs**: Processes all user queries from database
2. **Groups by user**: Collects all queries per user  
3. **Processes queries**: Finds new properties for each query
4. **Sends notification**: One notification per user with total count
5. **User receives**: "Found X new properties across Y searches"

### Batching Logic

- User with 1 query: "Found 3 new properties"  
- User with 3 queries: "Found 5 new properties across 3 searches"
- No notification sent if no new properties found

### Database Structure

```sql
-- Users' device tokens for push notifications
device_tokens:
  - id (UUID)
  - user_id (UUID, FK to auth.users)  
  - device_token (TEXT)
  - device_type (TEXT, default 'ios')
  - created_at (TIMESTAMP)
  - updated_at (TIMESTAMP)
```

## Testing

### Manual Testing

1. Ensure APNs configuration is correct
2. Run the property monitor: `npm run monitor`
3. Check logs for notification sending
4. Verify notifications appear on device

### Production Checklist

- [ ] Set `NODE_ENV=production` for production APNs
- [ ] Use production APNs certificates/keys
- [ ] Test with TestFlight or App Store build
- [ ] Monitor logs for delivery issues

## Troubleshooting

**No notifications received:**
- Check APNs credentials are correct
- Verify bundle ID matches app configuration  
- Ensure user granted notification permission
- Check device token was saved to database

**Notifications not grouped:**
- Verify queries have correct user_id
- Check monitor grouping logic in logs

**Certificate/key issues:**
- Use p8 auth keys instead of certificates (recommended)
- Ensure correct environment (development vs production)