// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ion_ads/src/appodeal/appodeal_ad_type.dart';
import 'package:ion_ads/src/appodeal/appodeal_native_ad_content_type.dart';
import 'package:ion_ads/src/appodeal/appodeal_services.dart';

//ignore_for_file: constant_identifier_names
/// Appodeal SDK Flutter Plugin main class.
///
/// This class declares the public API for the Appodeal SDK Flutter Plugin.
///
class Appodeal {
  Appodeal._();

  /// Rectangular ads that appear at the top/right/bottom/left or view of the device screen.
  static const BANNER = AppodealAdType.Banner;
  static const BANNER_RIGHT = AppodealAdType.BannerRight;
  static const BANNER_TOP = AppodealAdType.BannerTop;
  static const BANNER_LEFT = AppodealAdType.BannerLeft;
  static const BANNER_BOTTOM = AppodealAdType.BannerBottom;

  /// Interstitial ads are full-screen ads that cover the interface of their host app.
  static const INTERSTITIAL = AppodealAdType.Interstitial;

  /// Ads that reward users for watching short videos and interacting with playable ads and surveys.
  static const REWARDED_VIDEO = AppodealAdType.RewardedVideo;

  /// Rectangular ads (with defined size 300x250 dp) that appear at the view of the device screen.
  static const MREC = AppodealAdType.MREC;

  /// Native ad is a flexible type of advertising. You can adapt the display to your UI by preparing a template.
  static const NATIVE = AppodealAdType.NativeAd;

  /// Log level none for [setLogLevel] method.
  static const LogLevelNone = 0;

  /// Log level debug for [setLogLevel] method.
  static const LogLevelDebug = 1;

  /// Log level verbose for [setLogLevel] method.
  static const LogLevelVerbose = 2;

  static final _functions = <String, void Function(MethodCall call)?>{};

  // Handler for processing method calls.
  //ignore: prefer_function_declarations_over_variables
  static final Future<dynamic> Function(MethodCall call) _handler = (call) async {
    _functions[call.method]?.call(call);
    _functions.remove(call.method);
  };

  static final MethodChannel _channel = _defaultChannel(_handler);
  static const MethodChannel _interstitialChannel = MethodChannel('appodeal_flutter/interstitial');
  static const MethodChannel _rewardedVideoChannel = MethodChannel('appodeal_flutter/rewarded');
  static const MethodChannel _bannerChannel = MethodChannel('appodeal_flutter/banner');
  static const MethodChannel _mrecChannel = MethodChannel('appodeal_flutter/mrec');
  static const MethodChannel _nativeChannel = MethodChannel('appodeal_flutter/native');

  // Set [isTestMode] for getting test advertising.
  static void setTesting(bool isTestMode) {
    _channel.invokeMethod('setTestMode', {'isTestMode': isTestMode});
  }

  /// Check if test mode is enabled
  ///
  /// Returns `true` if test mode is enabled, otherwise `false`.
  static Future<bool?> isTesting() async {
    return _channel.invokeMethod('isTestMode');
  }

  /// Set [logLevel]
  ///
  /// Support log level: [LogLevelNone], [LogLevelDebug], [LogLevelVerbose]
  static void setLogLevel(int logLevel) {
    _channel.invokeMethod('setLogLevel', {'logLevel': logLevel});
  }

  /// Initialize the Appodeal SDK
  ///
  /// Initialize the Appodeal SDK with the [appKey] and List [adTypes] of the advertising you want to initialize.
  /// To find out about the end of initialization, use the [onInitializationFinished] callback
  static Future<void> initialize({
    required String appKey,
    required List<AppodealAdType> adTypes,
    void Function(List<ApdInitializationError>? errors)? onInitializationFinished,
  }) async {
    _functions['onInitializationFinished'] = (call) {
      final errors = call.arguments?['errors'] as List<String>? ?? <String>[];
      final error = List<ApdInitializationError>.from(errors.map(ApdInitializationError._));
      onInitializationFinished?.call(error);
    };
    return _channel.invokeMethod('initialize', {
      'appKey': appKey,
      'sdkVersion': getSDKVersion(),
      'adTypes':
          adTypes.fold<int>(0, (previousValue, element) => previousValue | element.platformType),
    });
  }

  /// Checks if [adType] is initialized.
  ///
  /// Returns `true` if the ad type is initialized, otherwise `false`.
  static Future<bool?> isInitialized(AppodealAdType adType) async {
    return _channel.invokeMethod('isInitialized', {'adType': adType.platformType});
  }

  /// Sets [isAutoCache] for new ads when current ads were shown for [adType].
  static void setAutoCache(AppodealAdType adType, bool isAutoCache) {
    _channel
        .invokeMethod('setAutoCache', {'adType': adType.platformType, 'isAutoCache': isAutoCache});
  }

  /// Checks if auto cache is enabled for [adType].
  ///
  /// Returns `true` if auto cache is enabled, otherwise `false`.
  static Future<bool?> isAutoCacheEnabled(AppodealAdType adType) async {
    return _channel.invokeMethod('isAutoCacheEnabled', {'adType': adType.platformType});
  }

  /// Starts caching ads for [adType].
  static Future<void> cache(AppodealAdType adType) {
    return _channel.invokeMethod('cache', {'adType': adType.platformType});
  }

  /// Checks if an ad is loaded for [adType].
  ///
  /// Returns `true` if ads are currently loaded and can be shown, otherwise `false`.
  static Future<bool?> isLoaded(AppodealAdType adType) async {
    return _channel.invokeMethod('isLoaded', {'adType': adType.platformShowType});
  }

  /// Checks if the loaded ad is a precache for [adType].
  ///
  /// Returns `true` if the currently loaded ads are precache, otherwise `false`.
  static Future<bool?> isPrecache(AppodealAdType adType) async {
    return _channel.invokeMethod('isPrecache', {'adType': adType.platformType});
  }

  /// Checks if an ad with a specific [adType] can be shown with [placement].
  ///
  /// Returns `true` if the ad can be shown with this placement, otherwise `false`.
  static Future<bool?> canShow(AppodealAdType adType, [String placement = 'default']) async {
    return _channel
        .invokeMethod('canShow', {'adType': adType.platformType, 'placement': placement});
  }

  /// Gets predicted eCPM for a certain [adType].
  static Future<double?> getPredictedEcpm(AppodealAdType adType) async {
    return _channel.invokeMethod('getPredictedEcpm', {'adType': adType.platformType});
  }

  /// Shows [adType] advertising with [placement].
  ///
  /// Returns `true` if the ad can be shown with this placement, otherwise `false`.
  static Future<bool?> show(AppodealAdType adType, [String placement = 'default']) async {
    return _channel
        .invokeMethod('show', {'adType': adType.platformShowType, 'placement': placement});
  }

  /// Hides [adType] advertising.
  ///
  /// Supports only [AppodealAdType.Banner] and [AppodealAdType.MREC].
  static void hide(AppodealAdType adType) {
    _channel.invokeMethod('hide', {'adType': adType.platformShowType});
  }

  /// Destroys [adType] advertising.
  ///
  /// Supports only [AppodealAdType.Banner] and [AppodealAdType.MREC].
  static void destroy(AppodealAdType adType) {
    if (Platform.isAndroid) {
      _channel.invokeMethod('destroy', {'adType': adType.platformType});
    }
  }

  /// Sets [isAdViewAutoResume] for the `Android` platform (default is `true`).
  ///
  /// If [isAdViewAutoResume] is `true`, the SDK will show AdView on all new activities without calling additional code from your side.
  /// If you want to control the display yourself, you can set [isAdViewAutoResume] to `false`.
  /// Supports only [AppodealAdType.Banner] and [AppodealAdType.MREC].
  static void setAdViewAutoResume(bool isAdViewAutoResume) {
    if (Platform.isAndroid) {
      _channel.invokeMethod('setAdViewAutoResume', {
        'isAdViewAutoResume': isAdViewAutoResume,
      });
    }
  }

  /// Checks if ad view auto resume is enabled for the `Android` platform (default is `true`).
  ///
  /// Returns `true` if ad view auto resume is enabled, otherwise `false`.
  static Future<bool?> isAdViewAutoResume() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('isAdViewAutoResume');
    }
    return false;
  }

  /// Sets [isSmartBannersEnabled] (`false` by default).
  static void setSmartBanners(bool isSmartBannersEnabled) {
    _channel.invokeMethod('setSmartBanners', {
      'isSmartBannersEnabled': isSmartBannersEnabled,
    });
  }

  /// Checks if smart banners are enabled (`false` by default).
  ///
  /// Returns `true` if smart banners are enabled, otherwise `false`.
  static Future<bool?> isSmartBanners() async {
    return _channel.invokeMethod('isSmartBanners');
  }

  /// Sets [isTabletBannerEnabled] (`false` by default).
  static void setTabletBanners(bool isTabletBannerEnabled) {
    _channel.invokeMethod('setTabletBanners', {
      'isTabletBannerEnabled': isTabletBannerEnabled,
    });
  }

  /// Checks if tablet banners are enabled (`false` by default).
  ///
  /// Returns `true` if tablet banners are enabled, otherwise `false`.
  static Future<bool?> isTabletBanners() async {
    return _channel.invokeMethod('isTabletBanners');
  }

  /// Sets [isBannerAnimationEnabled] (`true` by default).
  static void setBannerAnimation(bool isBannerAnimationEnabled) {
    _channel.invokeMethod('setBannerAnimation', {
      'isBannerAnimationEnabled': isBannerAnimationEnabled,
    });
  }

  /// Checks if banner animation is enabled (`false` by default).
  ///
  /// Returns `true` if banner animation is enabled, otherwise `false`.
  static Future<bool?> isBannerAnimation() async {
    return _channel.invokeMethod('isBannerAnimation');
  }

  /// Sets banners inverse rotation (by default: left = 90, right = -90).
  ///
  /// [leftBannerRotation] rotation for [AppodealAdType.BannerLeft], [AppodealAdType.BannerRight]
  static void setBannerRotation(int leftBannerRotation, int rightBannerRotation) {
    _channel.invokeMethod('setBannerRotation', {
      'leftBannerRotation': leftBannerRotation,
      'rightBannerRotation': rightBannerRotation,
    });
  }

  /// Disables specified [network] for [adType].
  static void disableNetwork(String network, [AppodealAdType adType = AppodealAdType.All]) {
    _channel.invokeMethod('disableNetwork', {
      'network': network,
      'adType': adType.platformType,
    });
  }

  /// Mutes video if [isMuteVideosIfCallsMuted] is `true` for `Android` platform (`false` by default).
  static void muteVideosIfCallsMuted(bool isMuteVideosIfCallsMuted) {
    if (Platform.isAndroid) {
      _channel.invokeMethod(
        'muteVideosIfCallsMuted',
        {'isMuteVideosIfCallsMuted': isMuteVideosIfCallsMuted},
      );
    }
  }

  /// Checks if muting videos when calls are muted is enabled for `Android` platform (`false` by default).
  ///
  /// Returns `true` if muting videos when calls are muted, otherwise `false`.
  static Future<bool?> isMuteVideosIfCallsMuted() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('isMuteVideosIfCallsMuted');
    }
    return false;
  }

  /// Disables data collection for kids' apps.
  ///
  /// If [isChildDirectedTreatment] is `true`, it disables data collection for kids' apps.
  static void setChildDirectedTreatment(bool isChildDirectedTreatment) {
    _channel.invokeMethod(
      'setChildDirectedTreatment',
      {'isChildDirectedTreatment': isChildDirectedTreatment},
    );
  }

  /// Checks if data collection for kids' apps is disabled (`false` by default).
  ///
  /// Returns `true` if data collection for kids' apps is disabled, otherwise `false`.
  static Future<bool?> isChildDirectedTreatment() async {
    return _channel.invokeMethod('isChildDirectedTreatment');
  }

  /// Sets use safe area [isUseSafeArea] for `Android` platform (`false` by default).
  ///
  /// Appodeal SDK will consider safe area when an ad is shown.
  /// Support only for [AppodealAdType.Banner] and [AppodealAdType.MREC]
  static void setUseSafeArea(bool isUseSafeArea) {
    if (Platform.isAndroid) {
      _channel.invokeMethod('setUseSafeArea', {'isUseSafeArea': isUseSafeArea});
    }
  }

  /// Checks if using safe area is enabled for `Android` platform (`false` by default).
  ///
  /// Returns `true` if using safe area is enabled, otherwise `false`.
  static Future<bool?> isUseSafeArea() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('isUseSafeArea');
    }
    return false;
  }

  /// Sets [userId].
  static void setUserId(String userId) {
    _channel.invokeMethod('setUserId', {'userId': userId});
  }

  /// Gets user Id.
  static Future<String?> getUserId() async {
    return _channel.invokeMethod('getUserId');
  }

  /// Sets custom segment filter [name] to [value].
  static void setCustomFilter(String name, dynamic value) {
    _channel.invokeMethod('setCustomFilter', {'name': name, 'value': value});
  }

  /// Sets custom extra data [key] to [value].
  static void setExtraData(String key, dynamic value) {
    _channel.invokeMethod('setExtraData', {'key': key, 'value': value});
  }

  /// Gets SDK version.
  static String getSDKVersion() {
    return '3.10.0';
  }

  /// Gets SDK platform version.
  static Future<String?> getPlatformSdkVersion() async {
    return _channel.invokeMethod('getPlatformSdkVersion');
  }

  /// Set preferred type of the requested Native ads.
  ///
  /// [contentType] type of Native ads [NativeMediaViewContentType].
  static void setPreferredNativeContentType(NativeMediaViewContentType contentType) {
    _channel.invokeMethod(
      'setPreferredNativeContentType',
      {'preferredNativeContentType': contentType.contentName},
    );
  }

  /// Get preferred type of the requested Native ads.
  ///
  /// Returns [NativeMediaViewContentType] of Native ads.
  static Future<NativeMediaViewContentType> getPreferredNativeContentType() async {
    final contentName = await _channel.invokeMethod('getPreferredNativeContentType');
    if (contentName == NativeMediaViewContentType.auto.contentName) {
      return NativeMediaViewContentType.auto;
    } else if (contentName == NativeMediaViewContentType.noVideo.contentName) {
      return NativeMediaViewContentType.noVideo;
    } else if (contentName == NativeMediaViewContentType.video.contentName) {
      return NativeMediaViewContentType.video;
    }
    return NativeMediaViewContentType.auto;
  }

  /// Get available native ads count.
  ///
  /// Returns count of available native ads.
  static Future<int?> getAvailableNativeAdsCount() async {
    return _channel.invokeMethod('getAvailableNativeAdsCount');
  }

  /// Logs an event with [eventName] and [params], sending to [service] or all services by default.
  static void logEvent(
    String eventName,
    Map<String, dynamic> params, [
    int service = AppodealServices.ALL,
  ]) {
    final validService = (service & ~AppodealServices.ALL) == 0 ? service : 0;
    if (validService == 0) {
      developer.log('Appodeal logEvent: No services were found');
    }
    _channel.invokeMethod('logEvent', {
      'eventName': eventName,
      'params': params,
      'service': validService,
    });
  }

  /// Sets Interstitial ads callbacks.
  ///
  /// [onInterstitialLoaded] Called when interstitial was loaded, `isPrecache` - `true` if interstitial is precache.
  /// [onInterstitialFailedToLoad] Called when interstitial fails to load. But if auto cache is enabled for interstitials, loading will be continued.
  /// [onInterstitialShown] Called when interstitial was shown.
  /// [onInterstitialShowFailed] Called when interstitial show fails.
  /// [onInterstitialClicked] Called when interstitial was clicked.
  /// [onInterstitialClosed] Called when interstitial was closed.
  /// [onInterstitialExpired] Called when interstitial was expired by time.
  static void setInterstitialCallbacks({
    void Function(bool isPrecache)? onInterstitialLoaded,
    Function? onInterstitialFailedToLoad,
    Function? onInterstitialShown,
    Function? onInterstitialShowFailed,
    Function? onInterstitialClicked,
    Function? onInterstitialClosed,
    Function? onInterstitialExpired,
  }) {
    _interstitialChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onInterstitialLoaded':
          onInterstitialLoaded?.call(call.arguments['isPrecache'] as bool? ?? false);
          break;
        case 'onInterstitialFailedToLoad':
          onInterstitialFailedToLoad?.call();
          break;
        case 'onInterstitialShown':
          onInterstitialShown?.call();
          break;
        case 'onInterstitialShowFailed':
          onInterstitialShowFailed?.call();
          break;
        case 'onInterstitialClicked':
          onInterstitialClicked?.call();
          break;
        case 'onInterstitialClosed':
          onInterstitialClosed?.call();
          break;
        case 'onInterstitialExpired':
          onInterstitialExpired?.call();
      }
    });
  }

  /// Sets Rewarded video ads callbacks.
  ///
  /// [onRewardedVideoLoaded] Called when rewarded video was loaded, `isPrecache` - `true` if rewarded video is precache.
  /// [onRewardedVideoFailedToLoad] Called when rewarded video fails to load. But if auto cache is enabled for rewarded videos, loading will be continued.
  /// [onRewardedVideoShown] Called when rewarded video was shown.
  /// [onRewardedVideoShowFailed] Called when rewarded video show fails.
  /// [onRewardedVideoClicked] Called when rewarded video was clicked.
  /// [onRewardedVideoFinished] Called when rewarded video was finished with the amount of reward and name of currency.
  /// [onRewardedVideoClosed] Called when rewarded video was closed, isFinished - `true` if video was finished.
  /// [onRewardedVideoExpired] Called when rewarded video was expired by time.
  static void setRewardedVideoCallbacks({
    void Function(bool isPrecache)? onRewardedVideoLoaded,
    Function? onRewardedVideoFailedToLoad,
    Function? onRewardedVideoShown,
    Function? onRewardedVideoShowFailed,
    Function? onRewardedVideoClicked,
    void Function(double amount, String reward)? onRewardedVideoFinished,
    void Function(bool isFinished)? onRewardedVideoClosed,
    Function? onRewardedVideoExpired,
  }) {
    _rewardedVideoChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRewardedVideoLoaded':
          onRewardedVideoLoaded?.call(call.arguments['isPrecache'] as bool? ?? false);
          break;
        case 'onRewardedVideoFailedToLoad':
          onRewardedVideoFailedToLoad?.call();
          break;
        case 'onRewardedVideoShown':
          onRewardedVideoShown?.call();
          break;
        case 'onRewardedVideoShowFailed':
          onRewardedVideoShowFailed?.call();
          break;
        case 'onRewardedVideoClicked':
          onRewardedVideoClicked?.call();
          break;
        case 'onRewardedVideoFinished':
          onRewardedVideoFinished?.call(
            call.arguments['amount'] as double? ?? 0.0,
            call.arguments['reward'] as String? ?? '',
          );
          break;
        case 'onRewardedVideoClosed':
          onRewardedVideoClosed?.call(call.arguments['isFinished'] as bool? ?? false);
          break;
        case 'onRewardedVideoExpired':
          onRewardedVideoExpired?.call();
      }
    });
  }

  /// Sets Banner ads callbacks.
  ///
  /// [onBannerLoaded] Called when banner was loaded, `isPrecache` - `true` if banner is precache.
  /// [onBannerFailedToLoad] Called when banner fails to load. But if auto cache is enabled for banners, loading will be continued.
  /// [onBannerShown] Called when banner was shown.
  /// [onBannerShowFailed] Called when banner show fails.
  /// [onBannerClicked] Called when banner was clicked.
  /// [onBannerExpired] Called when banner was expired by time.
  static void setBannerCallbacks({
    void Function(bool isPrecache)? onBannerLoaded,
    Function? onBannerFailedToLoad,
    Function? onBannerShown,
    Function? onBannerShowFailed,
    Function? onBannerClicked,
    Function? onBannerExpired,
  }) {
    _bannerChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onBannerLoaded':
          onBannerLoaded?.call(call.arguments['isPrecache'] as bool? ?? false);
          break;
        case 'onBannerFailedToLoad':
          onBannerFailedToLoad?.call();
          break;
        case 'onBannerShown':
          onBannerShown?.call();
          break;
        case 'onBannerShowFailed':
          onBannerShowFailed?.call();
          break;
        case 'onBannerClicked':
          onBannerClicked?.call();
          break;
        case 'onBannerExpired':
          onBannerExpired?.call();
      }
    });
  }

  /// Sets MREC ads callbacks.
  ///
  /// [onMrecLoaded] Called when MREC was loaded, `isPrecache` - `true` if MREC is precache.
  /// [onMrecFailedToLoad] Called when MREC fails to load. But if auto cache is enabled for MRECs, loading will be continued.
  /// [onMrecShown]Called when MREC was shown.
  /// [onMrecShowFailed] Called when MREC show fails.
  /// [onMrecClicked] Called when MREC was clicked.
  /// [onMrecExpired] Called when MREC was expired by time.
  static void setMrecCallbacks({
    void Function(bool isPrecache)? onMrecLoaded,
    Function? onMrecFailedToLoad,
    Function? onMrecShown,
    Function? onMrecShowFailed,
    Function? onMrecClicked,
    Function? onMrecExpired,
  }) {
    _mrecChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMrecLoaded':
          onMrecLoaded?.call(call.arguments['isPrecache'] as bool? ?? false);
          break;
        case 'onMrecFailedToLoad':
          onMrecFailedToLoad?.call();
          break;
        case 'onMrecShown':
          onMrecShown?.call();
          break;
        case 'onMrecShowFailed':
          onMrecShowFailed?.call();
          break;
        case 'onMrecClicked':
          onMrecClicked?.call();
          break;
        case 'onMrecExpired':
          onMrecExpired?.call();
      }
    });
  }

  /// Set Native ads callbacks
  ///
  /// [onNativeLoaded] Called when Native Ad was loaded.
  /// [onNativeFailedToLoad] Called when Native Ad is fail to load.
  /// [onNativeShown] Called when Native Ad was shown.
  /// [onNativeShowFailed] Called when Native Ad show failed.
  /// [onNativeClicked] Called when Native Ad was clicked.
  /// [onNativeExpired] Called when Native Ad was expired by time.
  static void setNativeCallbacks({
    void Function()? onNativeLoaded,
    void Function()? onNativeFailedToLoad,
    void Function()? onNativeShown,
    void Function()? onNativeShowFailed,
    void Function()? onNativeClicked,
    void Function()? onNativeExpired,
    void Function(String message)? onLog,
  }) {
    _nativeChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onNativeLoaded':
          onNativeLoaded?.call();
          break;
        case 'onNativeFailedToLoad':
          onNativeFailedToLoad?.call();
          break;
        case 'onNativeShown':
          onNativeShown?.call();
          break;
        case 'onNativeShowFailed':
          onNativeShowFailed?.call();
          break;
        case 'onNativeClicked':
          onNativeClicked?.call();
          break;
        case 'onLog':
          onLog?.call(call.arguments.toString());
          break;
        case 'onNativeExpired':
          onNativeExpired?.call();
      }
    });
  }

  ///  Set self-hosted Bidon environment endpoint
  ///
  ///  @param [endpoint] Bidon environment endpoint
  static void setBidonEndpoint(String endpoint) {
    _channel.invokeMethod('setBidonEndpoint', {'endpoint': endpoint});
  }

  /// Get self-hosted Bidon environment endpoint
  ///
  /// @return Bidon environment endpoint
  static Future<String?> getBidonEndpoint() async {
    return _channel.invokeMethod('getBidonEndpoint');
  }

  static Future<Map<String, dynamic>?> getNativeAd(int adCount) async {
    return _channel.invokeMapMethod<String, dynamic>('getNativeAd', {'count': adCount});
  }
}

MethodChannel _defaultChannel(Future<dynamic> Function(MethodCall call)? handler) {
  return const MethodChannel('appodeal_flutter')..setMethodCallHandler(handler);
}

/// Appodeal SDK Initialization Error class.
///
/// This class declares errors during initialization.
///
class ApdInitializationError {
  ApdInitializationError._(this.description);

  final String description;
}

/// Appodeal SDK In-App Validation Error class.
///
/// This class declares errors during in-app validation.
///
class ApdValidationError {
  ApdValidationError._(this.description);

  final String description;
}
