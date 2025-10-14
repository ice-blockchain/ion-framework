import 'package:flutter/material.dart';

import '../models/native_ad_asset.dart';

class NativeChatAd extends StatelessWidget {
  const NativeChatAd({super.key, required this.ad});
  final IonNativeAdAsset ad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ad.iconImage != null) CircleAvatar(backgroundImage: ad.iconImage, radius: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ad.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _AdTag(text: ad.attributionText),
                  ],
                ),
                const SizedBox(height: 4),
                Text(ad.body, style: Theme.of(context).textTheme.bodySmall),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(ad.callToAction),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdTag extends StatelessWidget {
  const _AdTag({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
