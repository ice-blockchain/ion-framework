// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/components/call_to_action_button.dart';
import 'package:ion_ads/src/components/media_asset_image.dart';
import 'package:ion_ads/src/components/star_rating.dart';
import 'package:ion_ads/src/config/theme_data.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeArticleAd extends StatelessWidget {
  const NativeArticleAd({required this.ad, super.key});

  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.adsColors.onTertiaryFill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ad.mediaAssets?.mainImage != null) ...[
            MainImageWithAdChoices(ad: ad),
          ],
          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                MediaAssetImage(path: ad.mediaAssets?.icon, width: 32, height: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.body,
                        style: theme.textPrimary.subtitle3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ad.rating != null && ad.rating! > 0 || true)
                        StarRating(
                          rating: 2,
                          color: theme.adsColors.onTertiaryBackground,
                          size: 12,
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                CallToActionButton(child: Text(ad.callToAction)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
