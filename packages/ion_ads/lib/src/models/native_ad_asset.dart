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
    this.mediaAssets,
  });

  factory IonNativeAdAsset.fromMap(Map<String, dynamic> map) {
    return IonNativeAdAsset(
      title: map['title'] as String? ?? '',
      body: map['description'] as String? ?? '',
      callToAction: map['callToAction'] as String? ?? '',
      // Ensure rating is cast correctly from a number to a double
      rating: (map['rating'] as num?)?.toDouble(),
      advertiser: map['adProvider'] as String?,
      // Ensure predictedEcpm is cast correctly from a number to a double
      // predictedEcpm: (map['predictedEcpm'] as num?)?.toDouble(),
      // Check if mediaAssets exists and is a map before creating the object
      mediaAssets: map['mediaAssets'] != null
          ? IonMediaAssets.fromMap(map['mediaAssets'] as Map<Object?, dynamic>)
          : null,
    );
  }

  final String title;
  final String body;
  final String callToAction;
  final ImageProvider<Object>? iconImage;
  final Widget? mediaContent; // video or large image
  final double? rating; // 0..5
  final String? advertiser;
  final String attributionText;
  final IonMediaAssets? mediaAssets;

  @override
  String toString() =>
      'IonNativeAdAsset (title: $title, body: $body, callToAction: $callToAction, advertiser: $advertiser'
      ', rating: $rating, attributionText: $attributionText, mediaAssets: $mediaAssets, iconImage: $iconImage, '
      'mediaContent: $mediaContent)';
}

class IonMediaAssets {
  IonMediaAssets({this.icon, this.mainImage, this.video});

  factory IonMediaAssets.fromMap(Map<Object?, dynamic> map) {
    return IonMediaAssets(
      icon: map['icon'] != null ? (map['icon'] as Map<Object?, dynamic>)['value'] as String? : null,
      mainImage: map['mainImage'] != null
          ? (map['mainImage'] as Map<Object?, dynamic>)['value'] as String?
          : null,
      video:
          map['video'] != null ? (map['video'] as Map<Object?, dynamic>)['value'] as String? : null,
    );
  }

  final String? icon;
  final String? mainImage;
  final String? video;

  @override
  String toString() => 'IonMediaAssets (icon: $icon, mainImage: $mainImage, video: $video)';
}
