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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MediaAssetImage(path: ad.mediaAssets?.icon, width: 32, height: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Text(ad.title, style: theme.textPrimary.subtitle2),
                    Text(ad.body, style: theme.textPrimary.subtitle3),
                    if (ad.rating != null && ad.rating! > 0)
                      StarRating(
                        rating: 4,
                        color: theme.adsColors.onTertiaryBackground,
                        size: 12,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: CallToActionButton(child: Text(ad.callToAction)),
              ),
            ],
          ),
          if (ad.mediaAssets?.mainImage != null) ...[
            const SizedBox(height: 10),
            MainImageWithAdChoices(ad: ad),
          ],
        ],
      ),
    );
  }
}
