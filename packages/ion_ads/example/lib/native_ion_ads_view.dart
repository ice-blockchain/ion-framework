// SPDX-License-Identifier: ice License 1.0

import 'dart:developer';

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

  @override
  void initState() {
    super.initState();
    loadNativeAd();
  }

  Future<void> loadNativeAd() async {
    nativeAdCount = await Appodeal.getAvailableNativeAdsCount() ?? 0;

    final isInitialized = await Appodeal.isInitialized(AppodealAdType.NativeAd);
    log('NativeAd isInitialized - $isInitialized');

    showNews = await Appodeal.canShow(AppodealAdType.NativeAd) ?? false;
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 20),
                      fixedSize: const Size(300, 20),
                    ),
                    onPressed: () async {
                      final nativeAds = await Appodeal.getNativeAd(1);
                      log('getNativeAd result:$nativeAds');
                      if (nativeAds != null) {
                        nativeAdAsset = IonNativeAdAsset.fromMap(nativeAds);
                        log('getNativeAd result:$nativeAdAsset');

                        setState(() {
                          isShow = true;
                        });
                      }
                    },
                    child: const Text('Show Native Ads'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: isShow && nativeAdAsset != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Feed'),
                          NativeAdCard(ad: nativeAdAsset!),
                          const SizedBox(height: 16),
                          const Text('Chat'),
                          SizedBox(
                            width: 270,
                            child: Expanded(
                              child: Card(
                                margin: EdgeInsets.zero,
                                elevation: 6,
                                child: NativeChatAd(ad: nativeAdAsset!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Chat List'),
                          Card(
                            elevation: 6,
                            child: NativeChatListAd(ad: nativeAdAsset!),
                          ),
                          const SizedBox(height: 16),
                          const Text('Article'),
                          NativeArticleAd(ad: nativeAdAsset!),
                          const SizedBox(height: 16),

                          const Text('NewsFeed Native Ad'),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              showNews = !showNews;
                              showCustom = false;
                            }),
                            child: const Text('Show NewsFeed Native Ad'),
                          ),
                          if (showNews)
                            SizedBox(
                              height: 100,
                              child: AppodealNativeAd(
                                key: const ValueKey('NewsFeed Native Ad'),
                                options: NativeAdOptions.newsFeedOptions(
                                  adChoicePosition: AdChoicePosition.endTop,
                                  adAttributionBackgroundColor: Colors.white,
                                  adAttributionTextColor: Colors.black,
                                  adActionButtonTextSize: 14,
                                  adDescriptionFontSize: 12,
                                  adTitleFontSize: 14,
                                ),
                              ),
                            ),

                          const Text('Custom Native Ad'),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              showNews = false;
                              showCustom = !showCustom;
                            }),
                            child: const Text('Show Custom Native Ad'),
                          ),
                          if (showCustom)
                            SizedBox(
                              height: 320,
                              child: AppodealNativeAd(
                                key: const ValueKey('Custom Native Ad'),
                                options: NativeAdOptions.customOptions(
                                  adIconConfig: AdIconConfig(size: 22),
                                ),
                              ),
                            ),

                          // const Text('AppWall Native Ad'),
                          // SizedBox(
                          //   height: 200,
                          //   child: AppodealNativeAd(
                          //     options: NativeAdOptions.appWallOptions(),
                          //   ),
                          // ),

                          // const Text('ContentStream Native Ad'),
                          // SizedBox(
                          //   height: 320,
                          //   child: AppodealNativeAd(
                          //     options: NativeAdOptions.contentStreamOptions(),
                          //   ),
                          // ),

                          // SizedBox(
                          //   height: 100,
                          //   child: NativeStoryAd(ad: nativeAdAsset!),
                          // ),
                          // const SizedBox(height: 16),
                          // SizedBox(
                          //   height: 100,
                          //   child: NativeVideoAd(ad: nativeAdAsset!),
                          // ),
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
}
