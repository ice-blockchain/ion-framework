// SPDX-License-Identifier: ice License 1.0

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ion_ads/ion_ads.dart';

class NativeIonPage extends StatefulWidget {
  const NativeIonPage({Key? key}) : super(key: key);

  @override
  State<NativeIonPage> createState() => _NativeIonPageState();
}

class _NativeIonPageState extends State<NativeIonPage> {
  bool isShow = false;
  IonNativeAdAsset? nativeAdAsset;
  int nativeAdCount = 0;

  bool showNews = false;
  bool showCustom = false;
  bool showContentStream = false;
  bool showAppWall = false;

  final nativeAdOptions = NativeAdOptions.customOptions(
    adIconConfig: AdIconConfig(size: 22),
  );

  final newsFeedOptions = NativeAdOptions.newsFeedOptions();

  @override
  void initState() {
    super.initState();
    loadNativeAd();
  }

  Future<void> loadNativeAd() async {
    nativeAdCount = await Appodeal.getAvailableNativeAdsCount() ?? 0;

    final isInitialized = await Appodeal.isInitialized(AppodealAdType.NativeAd);
    log('NativeAd isInitialized - $isInitialized');

    showCustom = await Appodeal.isInitialized(AppodealAdType.NativeAd) ?? false;
    final nativeAds = await Appodeal.getNativeAd(1);
    log('getNativeAd result:$nativeAds');
    if (nativeAds != null) {
      nativeAdAsset = IonNativeAdAsset.fromMap(nativeAds);
      log('getNativeAd result:$nativeAdAsset');

      setState(() {
        isShow = true;
      });
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('ION Native'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Appodeal.consentForm.load(
                        appKey: _exampleAppodealKey,
                        onConsentFormLoadFailure: onConsentFormDismissed,
                        onConsentFormLoadSuccess: (status) {
                          log('onConsentFormLoadSuccess: status - $status');
                        },
                      );
                    },
                    child: const Text('Load'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Appodeal.consentForm.revoke();
                    },
                    child: const Text('revoke'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Appodeal.consentForm.show(onConsentFormDismissed: onConsentFormDismissed);
                    },
                    child: const Text('Show '),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: isShow && nativeAdAsset != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NewsFeed Native Ad'),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              showNews = !showNews;
                              showCustom = false;
                            }),
                            child: Text('${!showNews ? 'Show' : 'Hide'} NewsFeed Native Ad'),
                          ),
                          if (showNews)
                            ClipRect(
                              child: SizedBox(
                                height: newsFeedOptions.getWidgetHeight(context),
                                child: AppodealNativeAd(
                                  key: const ValueKey('AppWall Native Ad'),
                                  options: newsFeedOptions,
                                ),
                              ),
                            ),
                          const Text('Custom Native Ad'),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              showNews = false;
                              showCustom = !showCustom;
                            }),
                            child: Text('${!showCustom ? 'Show' : 'Hide'} Custom Native Ad'),
                          ),
                          if (showCustom)
                            SizedBox(
                              height: nativeAdOptions.getWidgetHeight(context),
                              child: AppodealNativeAd(
                                key: const ValueKey('Custom Native Ad'),
                                options: nativeAdOptions,
                              ),
                            ),
                          const Text('AppWall Native Ad'),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              showNews = false;
                              showCustom = false;
                              showContentStream = false;
                              showAppWall = !showAppWall;
                            }),
                            child: Text('${!showAppWall ? 'Show' : 'Hide'} AppWall'),
                          ),
                          if (showAppWall)
                            SizedBox(
                              height: 100,
                              child: AppodealNativeAd(
                                options: NativeAdOptions.appWallOptions(),
                              ),
                            ),
                          const Text('ContentStream Native Ad'),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              showNews = false;
                              showCustom = false;
                              showAppWall = false;
                              showContentStream = !showContentStream;
                            }),
                            child: Text('${!showContentStream ? 'Show' : 'Hide'} ContentStream'),
                          ),
                          if (showContentStream)
                            SizedBox(
                              height: 380,
                              child: AppodealNativeAd(
                                options: NativeAdOptions.contentStreamOptions(),
                              ),
                            ),
                          const SizedBox(height: 56),
                        ],
                      )
                    : Text('NativeAdCount :$nativeAdCount'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onConsentFormDismissed(ConsentError? error) {
    if (error != null) {
      log('onConsentFormDismissed: error - ${error.description}');
    } else {
      log('onConsentFormDismissed: No error');
    }
  }
}

final String _exampleAppodealKey = Platform.isAndroid
    ? const String.fromEnvironment('AD_APP_KEY_ANDROID')
    : const String.fromEnvironment('AD_APP_KEY_IOS');
