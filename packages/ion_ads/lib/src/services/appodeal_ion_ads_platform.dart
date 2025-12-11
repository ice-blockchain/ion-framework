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

  @override
  Future<void> initialize({
    required String androidAppKey,
    required String iosAppKey,
    required bool hasConsent,
    bool testMode = true,
    bool verbose = false,
  }) async {
    Appodeal.setTesting(false); //only not release mode
    Appodeal.setLogLevel(verbose ? Appodeal.LogLevelVerbose : Appodeal.LogLevelNone);

    //Appodeal.setAutoCache(AppodealAdType.Interstitial, true);
    //Appodeal.setAutoCache(AppodealAdType.RewardedVideo, true);
    Appodeal.setAutoCache(AppodealAdType.NativeAd, true);
    Appodeal.setUseSafeArea(true);

    // Appodeal.setAdRevenueCallbacks(onAdRevenueReceive: (adRevenue) {
    //   print("onAdRevenueReceive: $adRevenue");
    // });

    await Appodeal.initialize(
      appKey: Platform.isAndroid ? androidAppKey : iosAppKey,
      adTypes: [
        //AppodealAdType.RewardedVideo,
        // AppodealAdType.Interstitial,
        // AppodealAdType.Banner,
        // AppodealAdType.MREC,
        AppodealAdType.NativeAd,
      ],
      onInitializationFinished: (errors) {
        errors?.forEach((error) => log(error.description));
        log('onInitializationFinished: errors - ${errors?.length ?? 0}');
      },
    );

    _setupAppodealCallbacks();
    await _checkAdAvailability();

    _initialized = true;
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
        _checkAdAvailability();
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
      onNativeLoaded: () {
        _isNativeLoaded = true;
        log('onNativeLoaded');
      },
      onNativeFailedToLoad: () {
        //_isNativeLoaded = false;
        log('onNativeFailedToLoad');
      },
      onNativeShown: () => log('onNativeShown'),
      onNativeShowFailed: () => log('onNativeShowFailed'),
      onNativeClicked: () => log('onNativeClicked'),
      onNativeExpired: () => log('onNativeExpired'),
    );
  }

  Future<void> _checkAdAvailability() async {
    //final bannerReady = await Appodeal.canShow(AppodealAdType.Banner);
    //final interstitialReady = await Appodeal.canShow(AppodealAdType.Interstitial);
    // final rewardedReady = await Appodeal.canShow(AppodealAdType.RewardedVideo);
    final isNativeInitialized = await Appodeal.isInitialized(AppodealAdType.NativeAd);
    final canShowNative = await Appodeal.canShow(AppodealAdType.NativeAd);
    final nativeAd = await Appodeal.getNativeAd(1);
    log('isNativeInitialized :$isNativeInitialized, canShowNative:$canShowNative, nativeAd:$nativeAd');

    await Appodeal.cache(AppodealAdType.NativeAd);

    // _isBannerLoaded = bannerReady ?? false;
    // _isInterstitialLoaded = interstitialReady ?? false;
    // _isRewardedLoaded = rewardedReady ?? false;
    _isNativeLoaded = isNativeInitialized ?? false;
  }

  @override
  bool isAvailable(IonNativeAdPlacement placement) {
    return _initialized;
  }

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
