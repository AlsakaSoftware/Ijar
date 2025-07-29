# Ijar - Property Search Platform

A comprehensive property search platform with iOS app and automated backend scraping.

## 🏗 Project Structure

```
├── Ijar-app/          # iOS SwiftUI Application
├── backend/           # Node.js Backend & Scraper
└── README.md          # This file
```

## 📱 iOS App (Ijar-app/)

Modern SwiftUI app for property searching and browsing.

### Features
- **Sign in with Apple** authentication
- **Swipe-based property browsing** (like/dismiss)
- **Custom search queries** with location, price, and property filters
- **Favorites system** for saved properties
- **Real-time updates** from daily scraping

### Tech Stack
- SwiftUI + iOS 18+
- Supabase (Database + Authentication)
- NavigationStack architecture
- MVVM-C pattern

### Getting Started
1. Open `Ijar-app/Ijar.xcodeproj` in Xcode
2. Add Supabase URL and API key to `SupabaseClient.swift`
3. Configure Sign in with Apple capability
4. Build and run

## 🔧 Backend (backend/)

Node.js scraper that fetches property data from Rightmove and saves to Supabase.

### Features
- **Automated scraping** via GitHub Actions (runs daily at 9 AM)
- **Property ranking** by recency and photo count
- **Supabase integration** for data storage
- **Duplicate detection** and data cleanup

### Getting Started
1. `cd backend && npm install`
2. Set up environment variables for Supabase
3. Configure `searches.json` with your property queries
4. Run locally: `npm run dev`

## 🚀 Deployment

### iOS App
Deploy to App Store Connect after setting up:
- Supabase database schema
- Sign in with Apple configuration
- App Store app registration

### Backend
- Runs automatically via GitHub Actions
- Configure secrets for Supabase credentials
- Modify schedule in `.github/workflows/` if needed

## 🔄 How It Works

1. **Users create searches** in the iOS app (location, price, bedrooms, etc.)
2. **Queries are saved** to Supabase database
3. **GitHub Actions runs** the scraper daily at 9 AM
4. **New properties are fetched** from Rightmove and saved to database
5. **Users see new properties** in the app to swipe through
6. **Liked properties** are saved to favorites

## 🛠 Tech Stack

- **Frontend**: SwiftUI, iOS 18+
- **Backend**: Node.js, TypeScript
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Sign in with Apple
- **Automation**: GitHub Actions
- **Data Source**: Rightmove

## 📋 Setup Requirements

1. **Supabase Project** with database schema
2. **Apple Developer Account** for Sign in with Apple
3. **GitHub Repository** with Actions enabled
4. **Environment Variables** for API keys

---

Built with ❤️ for finding the perfect home 🏠