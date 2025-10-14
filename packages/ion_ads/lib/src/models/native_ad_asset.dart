import 'package:flutter/widgets.dart';

class IonNativeAdAsset {
  const IonNativeAdAsset({
    required this.title,
    required this.body,
    required this.callToAction,
    this.iconImage,
    this.mediaContent,
    this.rating,
    this.advertiser,
    this.attributionText = 'Ad',
  });

  final String title;
  final String body;
  final String callToAction;
  final ImageProvider<Object>? iconImage;
  final Widget? mediaContent; // video or large image
  final double? rating; // 0..5
  final String? advertiser;
  final String attributionText;
}
