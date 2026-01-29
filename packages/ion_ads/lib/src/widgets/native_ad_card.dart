// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/components/call_to_action_button.dart';
import 'package:ion_ads/src/components/media_asset_image.dart';
import 'package:ion_ads/src/components/star_rating.dart';
import 'package:ion_ads/src/config/theme_data.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeAdCard extends StatelessWidget {
  const NativeAdCard({required this.ad, super.key});

  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.adsSpacing;

    return Padding(
      padding: EdgeInsets.all(spacing.marginContainer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MediaAssetImage(
                path: ad.mediaAssets?.icon,
                width: spacing.iconSizeDefault,
                height: spacing.iconSizeDefault,
              ),
              SizedBox(width: spacing.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad.body, style: theme.textPrimary.subtitle3),
                    if (ad.rating != null && ad.rating! > 0)
                      StarRating(
                        rating: ad.rating!,
                        color: theme.adsColors.onTertiaryBackground,
                        size: spacing.starRatingSize,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: CallToActionButton(
                  onPressed: null,
                  child: Text(ad.callToAction),
                ),
              ),
            ],
          ),
          if (ad.mediaAssets?.mainImage != null) ...[
            SizedBox(height: spacing.spacingM),
            SizedBox(height: spacing.borderRadiusDefault),
          ],
        ],
      ),
    );
  }
}
