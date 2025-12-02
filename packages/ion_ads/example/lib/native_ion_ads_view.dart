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

  @override
  void initState() {
    super.initState();

    loadNativeAd();
  }

  Future<void> loadNativeAd() async {
    nativeAdCount = await Appodeal.getAvailableNativeAdsCount() ?? 0;

    final isInitialized = await Appodeal.isInitialized(AppodealAdType.NativeAd);
    log('NativeAd isInitialized - $isInitialized');

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
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: isShow && nativeAdAsset != null
                    ? Column(
                        children: [
                          NativeAdCard(ad: nativeAdAsset!),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: NativeStoryAd(ad: nativeAdAsset!),
                          ),
                          const SizedBox(height: 16),
                          NativeArticleAd(ad: nativeAdAsset!),
                          const SizedBox(height: 16),
                          NativeChatAd(ad: nativeAdAsset!),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: NativeVideoAd(ad: nativeAdAsset!),
                          ),
                          const SizedBox(height: 16),
                          NativeChatListAd(ad: nativeAdAsset!),
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
