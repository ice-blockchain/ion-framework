// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/config/theme_data.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeStoryAd extends StatelessWidget {
  const NativeStoryAd({required this.ad, super.key});
  final IonNativeAdAsset ad;

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
          ),
        Positioned(
          left: spacing.paddingInnerHorizontal,
          right: spacing.paddingInnerHorizontal,
          bottom: spacing.screenEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      ad.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _Badge(text: ad.attributionText),
                ],
              ),
              SizedBox(height: spacing.spacingM),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).adsSpacing; // Access spacing here too

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(spacing.marginContainer),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.spacingM,
          vertical: spacing.spacingS,
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
