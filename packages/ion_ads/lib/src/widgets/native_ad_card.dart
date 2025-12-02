// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion_ads/src/config/theme_data.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeAdCard extends StatelessWidget {
  const NativeAdCard({required this.ad, super.key});

  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MediaAssetImage(path: ad.mediaAssets?.icon, width: 30, height: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Text(ad.title, style: theme.textPrimary.subtitle2),
                    Text(ad.body, style: theme.textPrimary.subtitle2),
                    if (ad.rating != null)
                      Text(
                        '${ad.rating} stars',
                        style: theme.textPrimary.subtitle2,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.adsColors.primaryAccent,
                    textStyle: theme.textOnPrimary.body,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Set the radius here
                    ),
                    padding:
                        const EdgeInsetsGeometry.directional(start: 20, top: 7, end: 20, bottom: 8),
                  ),
                  child: Text(ad.callToAction),
                ),
              ),
            ],
          ),
          if (ad.mediaAssets?.mainImage != null) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MediaAssetImage(path: ad.mediaAssets?.mainImage),
                ),
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: _Attribution(text: ad.attributionText),
                ),
                const PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: _AdChoices(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

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

class _Attribution extends StatelessWidget {
  const _Attribution({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.onPrimaryAccent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: context.textPrimary.caption4.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AdChoices extends StatelessWidget {
  const _AdChoices();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      padding: const EdgeInsets.only(left: 3, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: context.colors.onPrimaryAccent,
        borderRadius: BorderRadius.circular(5.54),
      ),
      child: SvgPicture.asset(
        'assets/images/ad_choices.svg',
        package: 'ion_ads',
      ),
    );
  }
}
