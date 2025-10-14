import 'package:flutter/material.dart';

import '../models/native_ad_asset.dart';

class NativeVideoAd extends StatelessWidget {
  const NativeVideoAd({super.key, required this.ad, this.overlay});

  final IonNativeAdAsset ad;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (ad.mediaContent != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ad.mediaContent,
          )
        else
          const ColoredBox(color: Colors.black),
        if (overlay != null) overlay!,
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  ad.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
