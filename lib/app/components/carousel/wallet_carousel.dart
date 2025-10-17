// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/carousel/carousel_with_dots.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class WalletCarouselItem extends StatelessWidget {
  const WalletCarouselItem({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
        border: Border.all(
          color: context.theme.appColors.onTertiaryFill,
          width: 0.5.s,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.theme.appTextThemes.title,
                ),
                SizedBox(height: 8.0.s),
                Text(
                  description,
                  style: context.theme.appTextThemes.body2.copyWith(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.0.s),
          Expanded(child: icon),
        ],
      ),
    );
  }
}

class WalletCarousel extends StatelessWidget {
  const WalletCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0.s),
      child: CarouselWithDots(
        items: [
          // The items are currently as mockups and will be replaced with the actual content later
          WalletCarouselItem(
            title: 'Portfolio',
            description: 'Track your balance, profits and transactions',
            icon: Assets.svg.walletPortfolio.icon(size: 80.s),
          ),
          WalletCarouselItem(
            title: 'Portfolio',
            description: 'Track your balance, profits and transactions',
            icon: Assets.svg.walletPortfolio.icon(size: 80.s),
          ),
          WalletCarouselItem(
            title: 'Portfolio',
            description: 'Track your balance, profits and transactions',
            icon: Assets.svg.walletPortfolio.icon(size: 80.s),
          ),
        ],
        height: 120.s,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        viewportFraction: 0.9.s,
        enlargeCenterPage: true,
        dotsSpacing: 4.s,
        dotsSize: 3.s,
        dotsActiveSize: 12.s,
        dotsActiveHeight: 3.s,
      ),
    );
  }
}
