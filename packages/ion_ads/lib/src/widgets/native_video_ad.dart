// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/config/theme_data.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeVideoAd extends StatelessWidget {
  const NativeVideoAd({required this.ad, super.key, this.overlay});

  final IonNativeAdAsset ad;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.adsSpacing;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (ad.mediaContent != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(spacing.borderRadiusDefault),
            child: ad.mediaContent,
          )
        else
          const ColoredBox(color: Colors.black),
        if (overlay != null) overlay!,
        Positioned(
          left: spacing.paddingInnerHorizontal,
          right: spacing.paddingInnerHorizontal,
          bottom: spacing.screenEdge,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  ad.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FilledButton(
                onPressed: null,
                child: Text(ad.callToAction),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
