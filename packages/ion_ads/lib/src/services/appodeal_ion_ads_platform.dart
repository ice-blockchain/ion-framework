// SPDX-License-Identifier: ice License 1.0

// import 'dart:io';
//
// import 'package:appodeal_flutter/appodeal_flutter.dart' as ap;
// import 'package:flutter/widgets.dart';
//
// import '../config/ads_config.dart';
// import '../models/ad_types.dart';
// import '../models/native_ad_asset.dart';
// import 'ads_platform.dart';
//
// class AppodealIonAdsPlatform implements IonAdsPlatform {
//   bool _initialized = false;
//
//   @override
//   Future<void> initialize({
//     required String androidAppKey,
//     required String iosAppKey,
//     required bool hasConsent,
//     bool testMode = false,
//     bool verbose = false,
//   }) async {
//     final resolvedAndroidKey = androidAppKey.isEmpty ? null : androidAppKey;
//     final resolvedIosKey = iosAppKey.isEmpty ? AdsConfig.iosAppodealAppKey : iosAppKey;
//
//     ap.Appodeal.setAppKeys(
//       androidAppKey: Platform.isAndroid ? resolvedAndroidKey : null,
//       iosAppKey: Platform.isIOS ? resolvedIosKey : null,
//     );
//     // Ensure native auto-cache and cache one
//     await ap.Appodeal.setAutoCache(ap.AdType.native, true);
//     await ap.Appodeal.initialize(
//       hasConsent: hasConsent,
//       adTypes: [ap.AdType.native],
//       testMode: testMode,
//       verbose: verbose,
//     );
//     await ap.Appodeal.cache(ap.AdType.native);
//     _initialized = true;
//   }
//
//   @override
//   Future<bool> isAvailable(IonNativeAdPlacement placement) async {
//     if (!_initialized) return false;
//     return ap.Appodeal.isReadyForShow(ap.AdType.native);
//   }
//
//   @override
//   Future<IonNativeAdAsset?> loadNativeAd({
//     required IonNativeAdPlacement placement,
//     Map<String, Object?>? targeting,
//   }) async {
//     // The flutter plugin doesn't expose a data object for native assets.
//     // It provides a platform view for banner/mrec only. For native, we rely on platform to show.
//     // We'll return a minimal placeholder; actual rendering should use platform view if required.
//     final ready = await ap.Appodeal.isReadyForShow(ap.AdType.native);
//     if (!ready) {
//       await ap.Appodeal.cache(ap.AdType.native);
//       return null;
//     }
//     return const IonNativeAdAsset(
//       title: 'Sponsored',
//       body: 'Sponsored content',
//       callToAction: 'Learn more',
//     );
//   }
//
//   @override
//   Widget? buildPlatformMediaView(IonNativeAdAsset adAsset) {
//     // The plugin exposes specific platform views for banner and mrec, not a dedicated native view.
//     // Return null so the app renders using our widgets; when plugin adds native view, wire it here.
//     return null;
//   }
// }
