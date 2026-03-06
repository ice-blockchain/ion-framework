// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ion_ads/ion_ads.dart';
import 'package:ion_ads/src/components/ad_choices_container.dart';
import 'package:ion_ads/src/components/attribution_text_container.dart';

class MediaAssetImage extends StatelessWidget {
  const MediaAssetImage({required this.path, super.key, this.width, this.height});

  final String? path;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final imagePath = path;
    if (imagePath == null) return const SizedBox.shrink();

    return imagePath.startsWith(RegExp(r'file:///|\/'))
        ? Image.file(File(imagePath), width: width, height: height)
        : Image.network(imagePath, width: width, height: height);
  }
}

class MainImageWithAdChoices extends StatelessWidget {
  const MainImageWithAdChoices({required this.ad, super.key});

  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: MediaAssetImage(path: ad.mediaAssets?.mainImage),
        ),
        PositionedDirectional(
          top: 8,
          start: 8,
          child: AttributionTextContainer(text: ad.attributionText),
        ),
        const PositionedDirectional(
          top: 8,
          end: 8,
          child: AdChoicesContainer(),
        ),
      ],
    );
  }
}
