// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeArticleAd extends StatelessWidget {
  const NativeArticleAd({super.key, required this.ad});
  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Sponsored', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 6),
            _Dot(),
            const SizedBox(width: 6),
            Text(ad.attributionText, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 8),
        Text(ad.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(ad.body, style: Theme.of(context).textTheme.bodyMedium),
        if (ad.mediaContent != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ad.mediaContent,
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () {},
            child: Text(ad.callToAction),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 4,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
      ),
    );
  }
}
