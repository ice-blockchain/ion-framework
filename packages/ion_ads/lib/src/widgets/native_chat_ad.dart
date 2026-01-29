// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/components/media_asset_image.dart';
import 'package:ion_ads/src/components/star_rating.dart';
import 'package:ion_ads/src/config/theme_data.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeChatAd extends StatelessWidget {
  const NativeChatAd({required this.ad, super.key});

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
                child: Row(
                  children: [
                    Text(ad.title, style: theme.textPrimary.subtitle3),
                    SizedBox(width: spacing.paddingInnerVertical),
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
            ],
          ),
          if (ad.mediaAssets?.mainImage != null) ...[
            SizedBox(height: spacing.borderRadiusDefault),
          ],
          SizedBox(height: spacing.iconSizeDefault),
          if (ad.callToAction.isNotEmpty)
            SizedBox(
              height: spacing.spacingM,
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.adsColors.primaryAccent,
                  textStyle: theme.textOnPrimary.body,
                  minimumSize: const Size(double.maxFinite, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.borderRadiusDefault),
                  ),
                ),
                child: Text(ad.callToAction),
              ),
            ),
        ],
      ),
    );
  }
}
