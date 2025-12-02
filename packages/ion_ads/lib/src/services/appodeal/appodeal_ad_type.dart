// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

//ignore_for_file: constant_identifier_names
enum AppodealAdType {
  /// Сonstant for SDK initialization without declaration types.
  /// If you want to run attribution and session metrics before you use ads
  None(initCodeAndroid: 0, initCodeIOS: 0, imprCodeIOS: 0),

  /// Rectangular ads that appear at the top/right/bottom/left or view of the device screen.
  Banner(initCodeAndroid: 4, initCodeIOS: 4, imprCodeIOS: 8),
  BannerBottom(initCodeAndroid: 8, initCodeIOS: 4, imprCodeIOS: 8),
  BannerTop(initCodeAndroid: 16, initCodeIOS: 4, imprCodeIOS: 4),
  BannerLeft(initCodeAndroid: 1024, initCodeIOS: 4, imprCodeIOS: 64),
  BannerRight(initCodeAndroid: 2048, initCodeIOS: 4, imprCodeIOS: 128),

  /// Interstitial ads are full-screen ads that cover the interface of their host app.
  Interstitial(initCodeAndroid: 3, initCodeIOS: 1, imprCodeIOS: 1),

  /// Ads that reward users for watching short videos and interacting with playable ads and surveys.
  RewardedVideo(initCodeAndroid: 128, initCodeIOS: 16, imprCodeIOS: 16),

  /// Rectangular ads (with defined size 300x250 dp) that appear at the view of the device screen.
  MREC(initCodeAndroid: 256, initCodeIOS: 32, imprCodeIOS: 0),

  /// Native ad is a flexible type of advertising. You can adapt the display to your UI by preparing a template.
  NativeAd(initCodeAndroid: 512, initCodeIOS: 8, imprCodeIOS: 0),

  /// Сonstant for internal SDK usage. We recommend using types separately and consciously.
  All(initCodeAndroid: 4095, initCodeIOS: 61, imprCodeIOS: 0);

  const AppodealAdType({
    required this.initCodeAndroid,
    required this.initCodeIOS,
    required this.imprCodeIOS,
  });

  final int initCodeAndroid;
  final int initCodeIOS;
  final int imprCodeIOS;

  /// Get platform-specific type
  int get platformType => Platform.isAndroid ? initCodeAndroid : initCodeIOS;

  /// Get platform-specific type for showing ads
  int get platformShowType => Platform.isAndroid ? initCodeAndroid : imprCodeIOS;

  /// Factory method to create an `AppodealAdType` from platform type
  static AppodealAdType byPlatformType(int platformType) {
    return AppodealAdType.values.firstWhere(
      (type) =>
          type.platformType == platformType ||
          (type.platformShowType == platformType && Platform.isIOS),
      orElse: () => AppodealAdType.None,
    );
  }
}
