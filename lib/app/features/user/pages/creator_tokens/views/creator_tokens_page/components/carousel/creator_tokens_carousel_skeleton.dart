// SPDX-License-Identifier: ice License 1.0

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/carousel/creator_tokens_carousel.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class CreatorTokensCarouselSkeleton extends StatelessWidget {
  const CreatorTokensCarouselSkeleton({
    this.itemsCount = 3,
    super.key,
  });

  final int itemsCount;

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      options: CarouselOptions(
        height: CreatorTokensCarousel.carouselHeight,
        viewportFraction: 0.75,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        enlargeStrategy: CenterPageEnlargeStrategy.zoom,
      ),
      itemCount: itemsCount,
      itemBuilder: (context, index, realIndex) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: CreatorTokensCarousel.carouselHorizontalPadding.s,
          ),
          child: const _CarouselCardSkeleton(),
        );
      },
    );
  }
}

class _CarouselCardSkeleton extends StatelessWidget {
  const _CarouselCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final primaryPlaceholder = colors.secondaryBackground.withValues(alpha: 0.25);
    final secondaryPlaceholder = colors.primaryBackground.withValues(alpha: 0.3);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0.s),
      ),
      clipBehavior: Clip.antiAlias,
      child: ProfileBackground(
        colors: useAvatarFallbackColors,
        child: Padding(
          padding: EdgeInsets.only(top: CreatorTokensCarousel.carouselTopPadding.s),
          child: Skeleton(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20.0.s),
                _SkeletonLine(
                  width: 140.0.s,
                  height: 16.0.s,
                  color: primaryPlaceholder,
                ),
                SizedBox(height: 8.0.s),
                _SkeletonLine(
                  width: 110.0.s,
                  height: 12.0.s,
                  color: primaryPlaceholder,
                ),
                SizedBox(height: 12.0.s),
                Container(
                  width: 78.0.s,
                  height: 24.0.s,
                  decoration: BoxDecoration(
                    color: secondaryPlaceholder,
                    borderRadius: BorderRadius.circular(12.0.s),
                  ),
                ),
                SizedBox(height: 20.0.s),
                _SkeletonStatsRow(
                  color: secondaryPlaceholder,
                  barColor: primaryPlaceholder,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonStatsRow extends StatelessWidget {
  const _SkeletonStatsRow({
    required this.color,
    required this.barColor,
  });

  final Color color;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12.0.s),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 10.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 16.0.s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20.0.s,
                  height: 20.0.s,
                  decoration: BoxDecoration(
                    color: barColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(height: 6.0.s),
                _SkeletonLine(
                  width: 44.0.s,
                  height: 8.0.s,
                  color: barColor,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
