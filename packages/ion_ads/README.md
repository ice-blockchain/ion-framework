# ion_ads

Ads SDK wrapper and reusable UI for Appodeal native ads.

## Status
- Platform abstraction + mock platform for UI dev
- Widgets for placements:
  - Feed (`NativeAdCard`)
  - Stories (`NativeStoryAd`)
  - Video fullscreen (`NativeVideoAd`)
  - Chat message (`NativeChatAd`)
  - Inside article (`NativeArticleAd`)
  - Chat list row (`NativeChatListAd`)
- `AdInsertionHelper` for X ± Y spacing

## Usage (mock)
```dart
final platform = MockIonAdsPlatform();
await platform.initialize(appKey: 'mock');
final ad = await platform.loadNativeAd(placement: IonNativeAdPlacement.feed);
if (ad != null) NativeAdCard(ad: ad);
```

## Next steps
- Implement `AppodealIonAdsPlatform` mapping Appodeal native assets to `IonNativeAdAsset`.
- Follow Appodeal plugin setup for Android/iOS and initialize with native ads.
- iOS: add `NSUserTrackingUsageDescription`, `GADApplicationIdentifier`, and SKAdNetworkItems required by mediated networks.
- Android: add `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" .../>` inside `<application>`.
- Ensure title, CTA, attribution, and icon/media are visible per policy.
