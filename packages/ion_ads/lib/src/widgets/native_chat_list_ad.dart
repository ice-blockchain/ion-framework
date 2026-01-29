// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/components/ad_choices_container.dart';
import 'package:ion_ads/src/components/attribution_text_container.dart';
import 'package:ion_ads/src/components/call_to_action_button.dart';
import 'package:ion_ads/src/components/media_asset_image.dart';
import 'package:ion_ads/src/components/star_rating.dart';
import 'package:ion_ads/src/config/theme_data.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeChatListAd extends StatelessWidget {
  const NativeChatListAd({required this.ad, super.key});
  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.adsSpacing;

    return ListTile(
      leading: MediaAssetImage(
        path: ad.mediaAssets?.icon,
        width: spacing.iconSizeLarge,
        height: spacing.iconSizeLarge,
      ),
      title: Text(ad.body, style: theme.textPrimary.subtitle3),
      subtitle: Row(
        children: [
          AttributionTextContainer(text: ad.attributionText),
          SizedBox(width: spacing.spacingS),
          const AdChoicesContainer(),
          SizedBox(width: spacing.spacingS),
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
      contentPadding: EdgeInsets.zero,
      trailing: CallToActionButton(
        onPressed: null,
        child: Icon(Icons.download_outlined, color: theme.adsColors.onPrimaryAccent),
      ),
    );
  }
}
