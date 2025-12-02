// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_ads/src/models/native_ad_asset.dart';

class NativeChatListAd extends StatelessWidget {
  const NativeChatListAd({required this.ad, super.key});
  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ad.iconImage != null ? CircleAvatar(backgroundImage: ad.iconImage) : null,
      title: Row(
        children: [
          Expanded(child: Text(ad.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          _AdChip(text: ad.attributionText),
        ],
      ),
      subtitle: Text(ad.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: FilledButton.tonal(onPressed: () {}, child: Text(ad.callToAction)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _AdChip extends StatelessWidget {
  const _AdChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
