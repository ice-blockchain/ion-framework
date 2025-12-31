// SPDX-License-Identifier: ice License 1.0

import 'dart:developer';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ion_ads/ion_ads.dart';

class AppodealIonAdsPlatform implements IonAdsPlatform {
  bool _initialized = false;

  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;
  bool _isNativeLoaded = false;

  bool _hasConsent = false;

  final AdInsertionHelper _insertionHelper = AdInsertionHelper(baseInterval: 3, randomDelta: 5);

  @override
  Future<void> initialize({
    required String androidAppKey,
    required String iosAppKey,
    required bool hasConsent,
    bool testMode = false,
    bool verbose = false,
    bool nativeOnly = true,
  }) async {
    _hasConsent = hasConsent;
    Appodeal.setTesting(testMode);
    Appodeal.setLogLevel(verbose ? Appodeal.LogLevelVerbose : Appodeal.LogLevelNone);
    Appodeal.setAutoCache(AppodealAdType.NativeAd, true);
    Appodeal.setUseSafeArea(true);

    if (hasConsent) {
      await Appodeal.consentForm.load(
        appKey: Platform.isAndroid ? androidAppKey : iosAppKey,
        onConsentFormLoadFailure: _onConsentFormDismissed,
        onConsentFormLoadSuccess: (status) {
          log('onConsentFormLoadSuccess: status - $status');
        },
      );
    }

    Appodeal.setAdRevenueCallbacks(
      onAdRevenueReceive: (adRevenue) {
        log('onAdRevenueReceive: $adRevenue');
      },
    );

    await Appodeal.initialize(
      appKey: Platform.isAndroid ? androidAppKey : iosAppKey,
      adTypes: nativeOnly
          ? [AppodealAdType.Banner, AppodealAdType.NativeAd]
          : [
              AppodealAdType.RewardedVideo,
              AppodealAdType.Interstitial,
              AppodealAdType.Banner,
              AppodealAdType.MREC,
              AppodealAdType.NativeAd,
            ],
      onInitializationFinished: (errors) async {
        errors?.forEach((error) => log(error.description));
        final platformVersion = await Appodeal.getPlatformSdkVersion();
        log('onInitializationFinished: errors - ${errors?.length ?? 0}, platformVersion:$platformVersion');
        await Appodeal.cache(AppodealAdType.NativeAd);
        _initialized = true;
      },
    );

    _setupAppodealCallbacks();
  }

  void _setupAppodealCallbacks() {
    // Banner callbacks
    Appodeal.setBannerCallbacks(
      onBannerLoaded: (isPrecache) {
        log('Banner loaded (precache: $isPrecache)');
        _isBannerLoaded = true;
      },
      onBannerFailedToLoad: () {
        log('Banner failed to load');
        _isBannerLoaded = false;
      },
      onBannerShown: () => log('Banner shown'),
      onBannerClicked: () => log('Banner clicked'),
      onBannerExpired: () {
        log('Banner expired');
        _isBannerLoaded = false;
      },
    );

    // Interstitial callbacks
    Appodeal.setInterstitialCallbacks(
      onInterstitialLoaded: (isPrecache) {
        log('Interstitial loaded (precache: $isPrecache)');
        _isInterstitialLoaded = true;
      },
      onInterstitialFailedToLoad: () {
        log('Interstitial failed to load');
        _isInterstitialLoaded = false;
      },
      onInterstitialShown: () => log('Interstitial shown'),
      onInterstitialClosed: () {
        debugPrint('Interstitial closed');
        _isInterstitialLoaded = false;
      },
      onInterstitialClicked: () => log('Interstitial clicked'),
      onInterstitialExpired: () {
        debugPrint('Interstitial expired');
        _isInterstitialLoaded = false;
      },
    );

    // Rewarded video callbacks
    Appodeal.setRewardedVideoCallbacks(
      onRewardedVideoLoaded: (isPrecache) {
        log('Rewarded video loaded (precache: $isPrecache)');
        _isRewardedLoaded = true;
      },
      onRewardedVideoFailedToLoad: () {
        log('Rewarded video failed to load');
        _isRewardedLoaded = false;
      },
      onRewardedVideoShown: () => log('Rewarded video shown'),
      onRewardedVideoClosed: (isFinished) {
        log('Rewarded video closed (finished: $isFinished)');
        if (isFinished) {
          //_showSnackBar('Reward earned!');
        }

        _isRewardedLoaded = false;
      },
      onRewardedVideoFinished: (amount, currency) {
        log('Rewarded video finished - Reward: $amount $currency');
      },
      onRewardedVideoClicked: () => log('Rewarded video clicked'),
      onRewardedVideoExpired: () {
        log('Rewarded video expired');
        _isRewardedLoaded = false;
      },
    );

    Appodeal.setNativeCallbacks(
      onNativeLoaded: () async {
        log('onNativeLoaded');
        await _checkAdAvailability();
      },
      onNativeFailedToLoad: () {
        log('onNativeFailedToLoad');
        _isNativeLoaded = false;
      },
      onNativeShown: () => log('onNativeShown'),
      onNativeShowFailed: () => log('onNativeShowFailed'),
      onNativeClicked: () => log('onNativeClicked'),
      onNativeExpired: () {
        log('onNativeExpired');
        _isNativeLoaded = false;
      },
      onLog: (message) => log('onLog: $message'),
    );
  }

  Future<void> _checkAdAvailability() async {
    final isNativeInitialized = await Appodeal.isInitialized(AppodealAdType.NativeAd);
    final nativeAdCount = await Appodeal.getAvailableNativeAdsCount() ?? 0;
    final canShowNative = await Appodeal.canShow(AppodealAdType.NativeAd);

    log('isNativeInitialized :$isNativeInitialized, canShowNative:$canShowNative, nativeAdCount:$nativeAdCount');

    _isNativeLoaded = (isNativeInitialized ?? false) && (nativeAdCount > 0);
  }

  @override
  bool isAvailable(IonNativeAdPlacement placement) {
    return _initialized;
  }

  @override
  void showConsentForm() {
    if (_hasConsent) {
      Appodeal.consentForm.show(onConsentFormDismissed: _onConsentFormDismissed);
    }
  }

  @override
  List<int> computeInsertionIndices(int contentCount, {int startOffset = 0}) =>
      _insertionHelper.computeInsertionIndices(contentCount, startOffset: startOffset);

  bool get isBannerLoaded => _isBannerLoaded;

  bool get isInterstitialLoaded => _isInterstitialLoaded;

  bool get isRewardedLoaded => _isRewardedLoaded;

  bool get isNativeLoaded => _isNativeLoaded;

  void _onConsentFormDismissed(ConsentError? error) {
    if (error != null) {
      log('onConsentFormDismissed: error - ${error.description}');
    } else {
      log('onConsentFormDismissed: No error');
    }
  }

  @override
  Future<bool?> canShow(AppodealAdType adType, [String placement = 'default']) =>
      Appodeal.canShow(adType, placement);

  @override
  Future<IonNativeAdAsset?> loadNativeAd({
    required IonNativeAdPlacement placement,
    Map<String, Object?>? targeting,
  }) async {
    // The flutter plugin doesn't expose a data object for native assets.
    // It provides a platform view for banner/mrec only. For native, we rely on platform to show.
    // We'll return a minimal placeholder; actual rendering should use platform view if required.
    final ready = await Appodeal.canShow(AppodealAdType.NativeAd) ?? false;
    if (!ready) {
      await Appodeal.cache(AppodealAdType.NativeAd);
      return null;
    }
    return const IonNativeAdAsset(
      title: 'Sponsored',
      body: 'Sponsored content',
      callToAction: 'Learn more',
    );
  }

  @override
  Widget? buildPlatformMediaView(IonNativeAdAsset adAsset) {
    // The plugin exposes specific platform views for banner and mrec, not a dedicated native view.
    // Return null so the app renders using our widgets; when plugin adds native view, wire it here.
    return null;
  }
}
