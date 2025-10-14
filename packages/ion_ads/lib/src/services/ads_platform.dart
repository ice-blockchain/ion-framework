import 'package:flutter/widgets.dart';

import '../models/ad_types.dart';
import '../models/native_ad_asset.dart';

abstract class IonAdsPlatform {
  Future<void> initialize({required String appKey});

  Future<bool> isAvailable(IonNativeAdPlacement placement);

  Future<IonNativeAdAsset?> loadNativeAd({
    required IonNativeAdPlacement placement,
    Map<String, Object?>? targeting,
  });

  /// Provides a platform media widget if the SDK needs a special view
  /// for tracking impressions/clicks. Otherwise can return null and
  /// the caller can render [IonNativeAdAsset.mediaContent].
  Widget? buildPlatformMediaView(IonNativeAdAsset adAsset);
}
