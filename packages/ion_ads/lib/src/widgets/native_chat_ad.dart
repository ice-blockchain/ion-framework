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
                child: Row(
                  children: [
                    Text(ad.title, style: theme.textPrimary.subtitle3),
                    const SizedBox(width: 6),
                    if (ad.rating != null && ad.rating! > 0 || true)
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
            ],
          ),
          if (ad.mediaAssets?.mainImage != null) ...[
            const SizedBox(height: 10),
            MainImageWithAdChoices(ad: ad),
          ],
          const SizedBox(height: 8),
          if (ad.callToAction.isNotEmpty)
            SizedBox(
              height: 30,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: theme.adsColors.primaryAccent,
                  textStyle: theme.textOnPrimary.body,
                  minimumSize: const Size(double.maxFinite, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
