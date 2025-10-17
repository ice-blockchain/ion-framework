# Appodeal Integration Setup Guide

This Flutter app is configured to use the Appodeal ad network with the `stack_appodeal_flutter` package (v3.10.0).

## Prerequisites

1. **Appodeal Account**: Sign up at [https://app.appodeal.com/](https://app.appodeal.com/)
2. **App Registration**: Register your app in the Appodeal dashboard to get your App Key
3. **Flutter SDK**: Ensure you have Flutter installed and configured

## Configuration Steps

### 1. Get Your Appodeal App Key

1. Go to [https://app.appodeal.com/](https://app.appodeal.com/)
2. Create a new app or select an existing one
3. Copy your App Key from the dashboard

### 2. Update the App Key

Replace `YOUR_APPODEAL_APP_KEY_HERE` with your actual Appodeal App Key in the following files:

#### In `lib/main.dart` (line 15):
```dart
const String appKey = 'YOUR_APPODEAL_APP_KEY_HERE';
```

#### In `android/app/src/main/AndroidManifest.xml` (line 16):
```xml
<meta-data
    android:name="com.appodeal.APP_ID"
    android:value="YOUR_APPODEAL_APP_KEY_HERE" />
```

### 3. Platform-Specific Setup

#### Android Configuration

The Android configuration is already set up in `android/app/src/main/AndroidManifest.xml` with:
- Required permissions (Internet, Network State, Location, Storage)
- Appodeal App ID meta-data

**Minimum SDK Version**: Android API 23 (Android 6.0) or higher

#### iOS Configuration

The iOS configuration is already set up in `ios/Runner/Info.plist` with:
- NSUserTrackingUsageDescription for ATT (App Tracking Transparency)
- NSAppTransportSecurity settings
- SKAdNetwork IDs for Appodeal mediation partners

**Minimum iOS Version**: iOS 12.0 or higher

### 4. Install Dependencies

Run the following command in your terminal:

```bash
flutter pub get
```

### 5. Test Mode

The app is currently configured to run in **test mode** for development:

```dart
Appodeal.setTesting(true);
```

This ensures you see test ads during development. **Remember to set this to `false` before releasing to production.**

## Features Implemented

### Ad Types
- **Banner Ads**: Show/hide banner ads at the bottom of the screen
- **Interstitial Ads**: Full-screen ads between content
- **Rewarded Video Ads**: Video ads that reward users for watching

### Ad Controls
The app provides buttons to:
- Show/hide banner ads
- Display interstitial ads
- Play rewarded video ads
- Refresh ad availability status

### Callbacks
The app implements comprehensive callbacks for all ad types:
- Load events (success/failure)
- Display events (shown/clicked/closed)
- Reward events (for rewarded videos)

## Running the App

### For Android:
```bash
flutter run
```

### For iOS:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Update your bundle identifier and signing settings
3. Run from Xcode or use:
```bash
flutter run
```

## Testing Ads

1. **Test Mode**: The app is configured with test mode enabled, so you'll see test ads
2. **Ad Loading**: Ads may take a few seconds to load on first launch
3. **No Fill**: If no ads appear, check:
   - Internet connection is active
   - App Key is correctly configured
   - Check logs for any errors

## Production Checklist

Before releasing to production:

- [ ] Replace test App Key with production App Key
- [ ] Set testing mode to false: `Appodeal.setTesting(false);`
- [ ] Test ad serving in production mode
- [ ] Implement proper GDPR/CCPA consent flow (currently set to `true` by default)
- [ ] Review and customize privacy policy
- [ ] Test on both Android and iOS devices

## Consent Management

Starting from Appodeal SDK 3.0, Stack Consent Manager is included by default. Consent is requested automatically on SDK initialization. For custom consent implementation, refer to the [Appodeal documentation](https://docs.appodeal.com/).

## Troubleshooting

### No Ads Showing
- Verify your App Key is correct
- Check internet connection
- Review logs with `Appodeal.setLogLevel(Appodeal.LogLevelVerbose)`
- Ensure ad networks are enabled in your Appodeal dashboard

### Build Errors
- Run `flutter clean` and `flutter pub get`
- For iOS: `cd ios && pod install && cd ..`
- Check minimum SDK versions (Android 23, iOS 12)

### Performance Issues
- Avoid initializing Appodeal multiple times
- Cache ads when appropriate
- Monitor memory usage with multiple ad types

## Additional Resources

- [Appodeal Documentation](https://docs.appodeal.com/)
- [stack_appodeal_flutter Package](https://pub.dev/packages/stack_appodeal_flutter)
- [Flutter Appodeal Plugin GitHub](https://github.com/appodeal/Appodeal-Flutter-Plugin)
- [Appodeal Dashboard](https://app.appodeal.com/)

## Code Structure

### Main Components

1. **Initialization** (`initializeAppodeal()`):
   - Sets up Appodeal SDK
   - Configures test mode and logging
   - Initializes ad types

2. **Callbacks** (`_setupAppodealCallbacks()`):
   - Handles ad lifecycle events
   - Updates UI state based on ad availability

3. **Ad Display Functions**:
   - `_showBanner()`: Display banner ad
   - `_hideBanner()`: Hide banner ad
   - `_showInterstitial()`: Show interstitial ad
   - `_showRewardedVideo()`: Show rewarded video ad

4. **Status Check** (`_checkAdAvailability()`):
   - Checks which ad types are ready to display
   - Updates UI indicators

## Support

For issues specific to:
- **Appodeal SDK**: Contact Appodeal support at support@appodeal.com
- **Flutter Plugin**: Open an issue on the [GitHub repository](https://github.com/appodeal/Appodeal-Flutter-Plugin/issues)
- **This Implementation**: Check the code comments and Flutter documentation
