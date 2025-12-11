// SPDX-License-Identifier: ice License 1.0

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ion_ads/ion_ads.dart';

class NativeIonFlutterPage extends StatefulWidget {
  const NativeIonFlutterPage({Key? key}) : super(key: key);

  @override
  State<NativeIonFlutterPage> createState() => _NativeIonPageState();
}

class _NativeIonPageState extends State<NativeIonFlutterPage> {
  bool isShow = false;
  IonNativeAdAsset? nativeAdAsset;

  @override
  void initState() {
    super.initState();
    loadNativeAd();
  }

  Future<void> loadNativeAd() async {
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
                          const SizedBox(height: 56),
                        ],
                      )
                    : const Text('NativeAd loading...'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
