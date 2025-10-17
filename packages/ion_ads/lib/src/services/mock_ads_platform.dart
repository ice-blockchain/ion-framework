import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/ad_types.dart';
import '../models/native_ad_asset.dart';
import 'ads_platform.dart';

class MockIonAdsPlatform implements IonAdsPlatform {
  @override
  Future<void> initialize(
      {required String androidAppKey,
      required String iosAppKey,
      required bool hasConsent,
      bool testMode = false,
      bool verbose = false}) async {}

  @override
  Future<bool> isAvailable(IonNativeAdPlacement placement) async => true;

  @override
  Future<IonNativeAdAsset?> loadNativeAd({
    required IonNativeAdPlacement placement,
    Map<String, Object?>? targeting,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return IonNativeAdAsset(
      title: 'Sponsored by Acme',
      body: 'Discover the new Acme Widget that boosts your productivity.',
      callToAction: 'Learn more',
      iconImage: null,
      mediaContent: null,
      rating: 4.6,
      advertiser: 'Acme Inc.',
      attributionText: 'Ad',
    );
  }

  @override
  Widget? buildPlatformMediaView(IonNativeAdAsset adAsset) => null;
}
