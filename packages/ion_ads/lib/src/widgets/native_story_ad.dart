// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeStoryAd extends StatelessWidget {
  const NativeStoryAd({required this.ad, super.key});
  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (ad.mediaContent != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ad.mediaContent,
          ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
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
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {},
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
