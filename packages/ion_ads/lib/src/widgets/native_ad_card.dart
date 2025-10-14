import 'package:flutter/material.dart';

import '../models/native_ad_asset.dart';

class NativeAdCard extends StatelessWidget {
  const NativeAdCard({super.key, required this.ad});

  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (ad.iconImage != null) CircleAvatar(backgroundImage: ad.iconImage, radius: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad.title, style: Theme.of(context).textTheme.titleMedium),
                      Text(ad.advertiser ?? '', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                _Attribution(text: ad.attributionText),
              ],
            ),
            const SizedBox(height: 8),
            Text(ad.body, style: Theme.of(context).textTheme.bodyMedium),
            if (ad.mediaContent != null) ...[
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ad.mediaContent,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () {},
                child: Text(ad.callToAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
