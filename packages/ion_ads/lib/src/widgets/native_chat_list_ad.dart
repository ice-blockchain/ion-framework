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

    return ListTile(
      leading: MediaAssetImage(path: ad.mediaAssets?.icon, width: 48, height: 48),
      title: Text(ad.body, style: theme.textPrimary.subtitle3),
      subtitle: Row(
        children: [
          AttributionTextContainer(text: ad.attributionText),
          const SizedBox(width: 4),
          const AdChoicesContainer(),
          const SizedBox(width: 4),
          StarRating(
            rating: 4,
            color: theme.adsColors.onTertiaryBackground,
            size: 12,
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      trailing: CallToActionButton(
        child: Icon(Icons.download_outlined, color: theme.adsColors.onPrimaryAccent),
      ),
    );
  }
}
