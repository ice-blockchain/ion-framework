// SPDX-License-Identifier: ice License 1.0

import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ion_ads/ion_ads.dart';
import 'package:ion_ads_appodeal_example/native_ion_ads_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appodeal Test',
      theme: _buildLightTheme(),
      home: const MyHomePage(title: 'Appodeal Integration Test'),
    );
  }
}

ThemeData _buildLightTheme() {
  final colors = AdsColorsExtension.defaultColors();
  final textThemes = AdsTextThemesExtension.defaultTextThemes();
  return ThemeData.light().copyWith(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    extensions: <ThemeExtension<dynamic>>[colors, textThemes],
    cupertinoOverrideTheme: const CupertinoThemeData().copyWith(
      primaryColor: colors.primaryAccent,
    ),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, Key? key}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Future<void> _initializeAppodeal() async {
  Appodeal.setTesting(!kReleaseMode); //only not release mode
  Appodeal.setLogLevel(Appodeal.LogLevelVerbose);

  Appodeal.setAutoCache(AppodealAdType.Interstitial, true);
  Appodeal.setAutoCache(AppodealAdType.RewardedVideo, true);
  Appodeal.setAutoCache(AppodealAdType.NativeAd, true);
  Appodeal.setUseSafeArea(true);
  Appodeal.setSmartBanners(true);

  // Appodeal.setAdRevenueCallbacks(onAdRevenueReceive: (adRevenue) {
  //   print("onAdRevenueReceive: $adRevenue");
  // });

  await Appodeal.initialize(
    // Replace with your actual Appodeal app key from https://app.appodeal.com/
    appKey: _exampleAppodealKey,
    adTypes: [
      //AppodealAdType.RewardedVideo,
      AppodealAdType.Interstitial,
      AppodealAdType.Banner,
      //AppodealAdType.MREC,
      AppodealAdType.NativeAd,
    ],
    onInitializationFinished: (errors) {
      errors?.forEach((error) => log(error.description));
      log('onInitializationFinished: errors - ${errors?.length ?? 0}');
    },
  );
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;
  bool _isNativeLoaded = false;

  @override
  void initState() {
    super.initState();

    setupAppodeal();
  }

  Future<void> setupAppodeal() async {
    // Initialize Appodeal
    await _initializeAppodeal();
    _setupAppodealCallbacks();
    await _checkAdAvailability();
  }

  void _setupAppodealCallbacks() {
    // Banner callbacks
    Appodeal.setBannerCallbacks(
      onBannerLoaded: (isPrecache) {
        debugPrint('Banner loaded (precache: $isPrecache)');
        setState(() => _isBannerLoaded = true);
      },
      onBannerFailedToLoad: () {
        debugPrint('Banner failed to load');
        setState(() => _isBannerLoaded = false);
      },
      onBannerShown: () => debugPrint('Banner shown'),
      onBannerClicked: () => debugPrint('Banner clicked'),
      onBannerExpired: () {
        debugPrint('Banner expired');
        setState(() => _isBannerLoaded = false);
      },
    );

    // Interstitial callbacks
    Appodeal.setInterstitialCallbacks(
      onInterstitialLoaded: (isPrecache) {
        debugPrint('Interstitial loaded (precache: $isPrecache)');
        setState(() => _isInterstitialLoaded = true);
      },
      onInterstitialFailedToLoad: () {
        debugPrint('Interstitial failed to load');
        setState(() => _isInterstitialLoaded = false);
      },
      onInterstitialShown: () => debugPrint('Interstitial shown'),
      onInterstitialClosed: () {
        debugPrint('Interstitial closed');
        setState(() => _isInterstitialLoaded = false);
        _checkAdAvailability();
      },
      onInterstitialClicked: () => debugPrint('Interstitial clicked'),
      onInterstitialExpired: () {
        debugPrint('Interstitial expired');
        setState(() => _isInterstitialLoaded = false);
      },
    );

    // Rewarded video callbacks
    Appodeal.setRewardedVideoCallbacks(
      onRewardedVideoLoaded: (isPrecache) {
        debugPrint('Rewarded video loaded (precache: $isPrecache)');
        setState(() => _isRewardedLoaded = true);
      },
      onRewardedVideoFailedToLoad: () {
        debugPrint('Rewarded video failed to load');
        setState(() => _isRewardedLoaded = false);
      },
      onRewardedVideoShown: () => debugPrint('Rewarded video shown'),
      onRewardedVideoClosed: (isFinished) {
        debugPrint('Rewarded video closed (finished: $isFinished)');
        if (isFinished) {
          _showSnackBar('Reward earned!');
        }
        setState(() => _isRewardedLoaded = false);
        _checkAdAvailability();
      },
      onRewardedVideoFinished: (amount, currency) {
        debugPrint('Rewarded video finished - Reward: $amount $currency');
      },
      onRewardedVideoClicked: () => debugPrint('Rewarded video clicked'),
      onRewardedVideoExpired: () {
        debugPrint('Rewarded video expired');
        setState(() => _isRewardedLoaded = false);
      },
    );

    Appodeal.setNativeCallbacks(
      onNativeLoaded: () {
        log('NativeCallback: onNativeLoaded');
        setState(() => _isNativeLoaded = true);
      },
      onNativeFailedToLoad: () => log('NativeCallback: onNativeFailedToLoad'),
      onNativeShown: () => log('NativeCallback: onNativeShown'),
      onNativeShowFailed: () => log('NativeCallback: onNativeShowFailed'),
      onNativeClicked: () => log('NativeCallback: onNativeClicked'),
      onNativeExpired: () => log('NativeCallback: onNativeExpired'),
      onLog: (message) => log('NativeCallback: $message'),
    );
  }

  Future<void> _checkAdAvailability() async {
    await Appodeal.cache(AppodealAdType.NativeAd);

    final bannerReady = await Appodeal.canShow(AppodealAdType.Banner);
    final interstitialReady = await Appodeal.canShow(AppodealAdType.Interstitial);
    final rewardedReady = await Appodeal.canShow(AppodealAdType.RewardedVideo);
    final isNativeInitialized = await Appodeal.isInitialized(AppodealAdType.NativeAd);

    setState(() {
      _isBannerLoaded = bannerReady ?? false;
      _isInterstitialLoaded = interstitialReady ?? false;
      _isRewardedLoaded = rewardedReady ?? false;
      _isNativeLoaded = isNativeInitialized ?? false;
    });
  }

  void _showBanner() {
    Appodeal.show(AppodealAdType.Banner);
  }

  void _hideBanner() {
    Appodeal.hide(AppodealAdType.Banner);
    _showSnackBar('Banner hidden');
  }

  Future<void> _showInterstitial() async {
    if (_isInterstitialLoaded) {
      await Appodeal.show(AppodealAdType.Interstitial);
    } else {
      _showSnackBar('Interstitial not ready yet');
    }
  }

  Future<void> _showRewardedVideo() async {
    if (_isRewardedLoaded) {
      await Appodeal.show(AppodealAdType.RewardedVideo);
    } else {
      _showSnackBar('Rewarded video not ready yet');
    }
  }

  Future<void> _showNativeAds() async {
    if (_isNativeLoaded) {
      await Navigator.push(
        context,
        MaterialPageRoute<NativeIonPage>(builder: (context) => const NativeIonPage()),
      );
      //await Appodeal.show(AppodealAdType.RewardedVideo);
    } else {
      _showSnackBar('Native ads not ready yet');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Appodeal Ad Integration Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Banner Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Banner Ad ${_isBannerLoaded ? '(Ready)' : '(Loading...)'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(onPressed: _showBanner, child: const Text('Show Banner')),
                        ElevatedButton(onPressed: _hideBanner, child: const Text('Hide Banner')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interstitial Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Interstitial Ad ${_isInterstitialLoaded ? '(Ready)' : '(Loading...)'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _showInterstitial,
                      child: const Text('Show Interstitial'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rewarded Video Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Rewarded Video ${_isRewardedLoaded ? '(Ready)' : '(Loading...)'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _showRewardedVideo,
                      child: const Text('Show Rewarded Video'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Native ADS Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Native ADS ${_isNativeLoaded ? '(Ready)' : '(Loading...)'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _showNativeAds,
                      child: const Text('Show Native ADS'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _checkAdAvailability,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Ad Status'),
            ),
          ],
        ),
      ),
    );
  }
}

final String _exampleAppodealKey = Platform.isAndroid
    ? const String.fromEnvironment('AD_APP_KEY_ANDROID')
    : const String.fromEnvironment('AD_APP_KEY_IOS');
