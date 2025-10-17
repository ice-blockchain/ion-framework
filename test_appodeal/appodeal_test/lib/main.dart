import 'package:flutter/material.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Appodeal
  await initializeAppodeal();

  runApp(const MyApp());
}

Future<void> initializeAppodeal() async {
  // Replace with your actual Appodeal app key from https://app.appodeal.com/
  const String appKey = 'YOUR_APPODEAL_APP_KEY_HERE';

  // Set test mode to true for development
  Appodeal.setTesting(true);

  // Enable logging for debugging
  Appodeal.setLogLevel(Appodeal.LogLevelVerbose);

  // Initialize Appodeal with ad types you want to use
  await Appodeal.initialize(
    appKey: appKey,
    adTypes: [
      AppodealAdType.Interstitial,
      AppodealAdType.Banner,
      AppodealAdType.RewardedVideo,
    ],
    onInitializationFinished: (errors) {
      if (errors != null && errors.isNotEmpty) {
        debugPrint('Appodeal initialization errors: $errors');
      } else {
        debugPrint('Appodeal initialized successfully');
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appodeal Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Appodeal Integration Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  @override
  void initState() {
    super.initState();
    _setupAppodealCallbacks();
    _checkAdAvailability();
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
  }

  Future<void> _checkAdAvailability() async {
    final bannerReady = await Appodeal.canShow(AppodealAdType.Banner);
    final interstitialReady = await Appodeal.canShow(AppodealAdType.Interstitial);
    final rewardedReady = await Appodeal.canShow(AppodealAdType.RewardedVideo);

    setState(() {
      _isBannerLoaded = bannerReady;
      _isInterstitialLoaded = interstitialReady;
      _isRewardedLoaded = rewardedReady;
    });
  }

  void _showBanner() {
    Appodeal.show(AppodealAdType.Banner);
    _showSnackBar('Banner shown at bottom');
  }

  void _hideBanner() {
    Appodeal.hide(AppodealAdType.Banner);
    _showSnackBar('Banner hidden');
  }

  void _showInterstitial() async {
    if (_isInterstitialLoaded) {
      Appodeal.show(AppodealAdType.Interstitial);
    } else {
      _showSnackBar('Interstitial not ready yet');
    }
  }

  void _showRewardedVideo() async {
    if (_isRewardedLoaded) {
      Appodeal.show(AppodealAdType.RewardedVideo);
    } else {
      _showSnackBar('Rewarded video not ready yet');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                padding: const EdgeInsets.all(16.0),
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
                        ElevatedButton(
                          onPressed: _showBanner,
                          child: const Text('Show Banner'),
                        ),
                        ElevatedButton(
                          onPressed: _hideBanner,
                          child: const Text('Hide Banner'),
                        ),
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
                padding: const EdgeInsets.all(16.0),
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
                padding: const EdgeInsets.all(16.0),
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
