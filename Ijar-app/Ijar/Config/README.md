# Configuration Setup

## Setting up Config.plist

The app uses a `Config.plist` file to store sensitive configuration values like Supabase keys. This file is excluded from version control for security.

### Setup Steps:

1. **Copy the example file:**
   ```bash
   cp Config.example.plist Config.plist
   ```

2. **Update Config.plist with your values:**
   - `SupabaseURL`: Your Supabase project URL (e.g., `https://your-project-id.supabase.co`)
   - `SupabaseAnonKey`: Your Supabase anonymous/public key
   - `Environment`: Set to `Development` or `Production`

3. **Get your Supabase keys:**
   - Go to your [Supabase Dashboard](https://supabase.com/dashboard)
   - Select your project
   - Go to Settings > API
   - Copy the URL and anon/public key

### File Structure:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SupabaseURL</key>
	<string>https://your-project-id.supabase.co</string>
	<key>SupabaseAnonKey</key>
	<string>your-supabase-anon-key-here</string>
	<key>Environment</key>
	<string>Development</string>
</dict>
</plist>
```

## Security Notes:

- ✅ `Config.plist` is in `.gitignore` and won't be committed
- ✅ `Config.example.plist` is safe to commit (contains no real keys)
- ✅ ConfigManager validates that placeholder values aren't used
- ✅ Debug logging shows truncated keys for verification

## Troubleshooting:

**App crashes on launch?**
- Make sure `Config.plist` exists in the Config folder
- Verify all keys are filled with real values (not placeholders)
- Check that the Supabase URL is valid

**Authentication not working?**
- Verify your Supabase keys are correct
- Make sure Apple Sign In is enabled in your Supabase project
- Check Xcode console for ConfigManager debug output