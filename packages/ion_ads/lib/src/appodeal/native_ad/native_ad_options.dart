// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/appodeal/appodeal_platform_arguments.dart';
import 'package:ion_ads/src/appodeal/native_ad/models/ad_action_button.dart';
import 'package:ion_ads/src/appodeal/native_ad/models/ad_attribution.dart';
import 'package:ion_ads/src/appodeal/native_ad/models/ad_choice.dart';
import 'package:ion_ads/src/appodeal/native_ad/models/ad_description.dart';
import 'package:ion_ads/src/appodeal/native_ad/models/ad_icon.dart';
import 'package:ion_ads/src/appodeal/native_ad/models/ad_media.dart';
import 'package:ion_ads/src/appodeal/native_ad/models/ad_title.dart';

// ignore_for_file: prefer_constructors_over_static_methods
class NativeAdOptions with AppodealPlatformArguments {
  NativeAdOptions._({
    required this.nativeAdType,
    required this.adTitleConfig,
    required this.adAttributionConfig,
    required this.adChoiceConfig,
    required this.adIconConfig,
    required this.adDescriptionConfig,
    required this.adActionButtonConfig,
    required this.adMediaConfig,
  });

  /// Generates custom Native Ad View options
  NativeAdOptions.customOptions({
    AdTitleConfig? adTitleConfig,
    AdAttributionConfig? adAttributionConfig,
    AdChoiceConfig? adChoiceConfig,
    AdIconConfig? adIconConfig,
    AdDescriptionConfig? adDescriptionConfig,
    AdActionButtonConfig? adActionButtonConfig,
    AdMediaConfig? adMediaConfig,
    NativeAdType? nativeAdType,
  }) : this._(
          nativeAdType: nativeAdType ?? NativeAdType.custom,
          adTitleConfig: adTitleConfig ?? AdTitleConfig(),
          adAttributionConfig: adAttributionConfig ?? AdAttributionConfig(),
          adChoiceConfig: adChoiceConfig ?? AdChoiceConfig(),
          adIconConfig: adIconConfig ?? AdIconConfig(),
          adDescriptionConfig: adDescriptionConfig ?? AdDescriptionConfig(),
          adActionButtonConfig: adActionButtonConfig ?? AdActionButtonConfig(),
          adMediaConfig: adMediaConfig ?? AdMediaConfig(),
        );

  /// Generates template Native Ad View options
  NativeAdOptions._templateOptions({
    required NativeAdType nativeAdType,
    int? adIconSize,
    int? adTitleFontSize,
    int? adActionButtonTextSize,
    int? adDescriptionFontSize,
    Color? adAttributionTextColor,
    Color? adAttributionBackgroundColor,
    AdChoiceConfig? adChoiceConfig,
    bool? adIconVisible,
    bool? adMediaVisible,
  }) : this._(
          nativeAdType: nativeAdType,
          adTitleConfig: AdTitleConfig(fontSize: adTitleFontSize ?? 16),
          adAttributionConfig: AdAttributionConfig(
            textColor: adAttributionTextColor ?? Colors.black,
            backgroundColor: adAttributionBackgroundColor ?? Colors.transparent,
          ),
          adChoiceConfig: adChoiceConfig ?? AdChoiceConfig(),
          adIconConfig: AdIconConfig(visible: adIconVisible ?? true, size: adIconSize ?? 50),
          adDescriptionConfig: AdDescriptionConfig(fontSize: adDescriptionFontSize ?? 14),
          adActionButtonConfig: AdActionButtonConfig(
            fontSize: adActionButtonTextSize ?? 14,
            backgroundColor: Colors.blueAccent,
            textColor: Colors.white,
          ),
          adMediaConfig: AdMediaConfig(visible: adMediaVisible ?? true),
        );

  final NativeAdType nativeAdType;
  final AdTitleConfig adTitleConfig;
  final AdAttributionConfig adAttributionConfig;
  final AdChoiceConfig adChoiceConfig;
  final AdIconConfig adIconConfig;
  final AdDescriptionConfig adDescriptionConfig;
  final AdActionButtonConfig adActionButtonConfig;
  final AdMediaConfig adMediaConfig;

  /// Generates Content Stream template Native Ad View options
  static NativeAdOptions contentStreamOptions({
    int? adTitleFontSize,
    int? adActionButtonTextSize,
    int? adDescriptionFontSize,
    Color? adAttributionTextColor,
    Color? adAttributionBackgroundColor,
    AdChoiceConfig? adChoiceConfig,
  }) {
    return NativeAdOptions._templateOptions(
      nativeAdType: NativeAdType.contentStream,
      adIconSize: 32,
      adTitleFontSize: adTitleFontSize,
      adActionButtonTextSize: adActionButtonTextSize,
      adDescriptionFontSize: adDescriptionFontSize,
      adAttributionTextColor: adAttributionTextColor,
      adAttributionBackgroundColor: adAttributionBackgroundColor,
      adChoiceConfig: adChoiceConfig,
      adIconVisible: false,
      adMediaVisible: true,
    );
  }

  /// Generates App Wall template Native Ad View options
  static NativeAdOptions appWallOptions({
    int? adTitleFontSize,
    int? adActionButtonTextSize,
    int? adDescriptionFontSize,
    Color? adAttributionTextColor,
    Color? adAttributionBackgroundColor,
    AdChoiceConfig? adChoiceConfig,
  }) {
    return NativeAdOptions._templateOptions(
      nativeAdType: NativeAdType.appWall,
      adIconSize: 32,
      adTitleFontSize: adTitleFontSize,
      adActionButtonTextSize: adActionButtonTextSize,
      adDescriptionFontSize: adDescriptionFontSize,
      adAttributionTextColor: adAttributionTextColor,
      adAttributionBackgroundColor: adAttributionBackgroundColor,
      adChoiceConfig: adChoiceConfig,
      adIconVisible: true,
      adMediaVisible: true,
    );
  }

  /// Generates News Feed template Native Ad View options
  static NativeAdOptions newsFeedOptions({
    int? adTitleFontSize,
    int? adActionButtonTextSize,
    int? adDescriptionFontSize,
    Color? adAttributionTextColor,
    Color? adAttributionBackgroundColor,
    AdChoiceConfig? adChoiceConfig,
  }) {
    return NativeAdOptions._templateOptions(
      nativeAdType: NativeAdType.newsFeed,
      adIconSize: 32,
      adTitleFontSize: adTitleFontSize,
      adActionButtonTextSize: adActionButtonTextSize,
      adDescriptionFontSize: adDescriptionFontSize,
      adAttributionTextColor: adAttributionTextColor,
      adAttributionBackgroundColor: adAttributionBackgroundColor,
      adChoiceConfig: adChoiceConfig,
      adIconVisible: false,
      adMediaVisible: false,
    );
  }

  double getWidgetHeight(BuildContext context) {
    final width = getWidgetWidth(context);
    switch (nativeAdType) {
      case NativeAdType.newsFeed:
        return width * 0.8;
      case NativeAdType.appWall:
        return width * 2;
      case NativeAdType.chat:
        return width * 0.8;
      case NativeAdType.contentStream:
        return width * 0.764;
      case NativeAdType.custom:
        return getAdHeight(context, width);
    }
  }

  double getWidgetWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // TODO: two methods for get height
  double getAdHeight(BuildContext context, double width) {
    double height = 0;
    if (!adMediaConfig.visible && !adIconConfig.visible) {
      return 0;
    }

    if (adMediaConfig.visible) {
      height = width * 0.563; // 9:16
    }
    if (adIconConfig.visible) {
      height = height + adIconConfig.size;
    } else {
      height = height + 50; // height + adIconConfig._defaultSize;
    }
    return height;
  }

  /// Convert to map to pass to NativeAdOptions in NativeAd
  @override
  Map<String, dynamic> get toMap => <String, dynamic>{
        'nativeAdType': nativeAdType.index,
        'adMediaConfig': adMediaConfig.toMap,
        'adTitleConfig': adTitleConfig.toMap,
        'adAttributionConfig': adAttributionConfig.toMap,
        'adChoiceConfig': adChoiceConfig.toMap,
        'adIconConfig': adIconConfig.toMap,
        'adDescriptionConfig': adDescriptionConfig.toMap,
        'adActionButtonConfig': adActionButtonConfig.toMap,
      };
}

enum NativeAdType { custom, contentStream, appWall, newsFeed, chat }
