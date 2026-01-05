// SPDX-License-Identifier: ice License 1.0

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/carousel/creator_tokens_carousel.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

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
        height: CreatorTokensCarousel.carouselHeight.s,
        viewportFraction: 0.75,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
        enlargeStrategy: CenterPageEnlargeStrategy.zoom,
        initialPage: itemsCount >= 2 ? 1 : 0,
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
    final primary = colors.secondaryBackground.withValues(alpha: 0.25);
    final secondary = colors.primaryBackground.withValues(alpha: 0.3);

    return Container(
      height: 251.s,
      width: 205.s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0.s),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsetsDirectional.only(top: NavigationAppBar.screenHeaderHeight / 2),
      child: ProfileBackground(
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            top: 26.s,
          ),
          child: Skeleton(
            baseColor: secondary.withValues(alpha: 0.35),
            highlightColor: primary.withValues(alpha: 0.65),
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90.0.s,
                    height: 90.0.s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0.s),
                      color: secondary,
                    ),
                  ),
                  SizedBox(height: 10.0.s),
                  Container(
                    width: 180.0.s,
                    height: 20.0.s,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(10.0.s),
                    ),
                  ),
                  SizedBox(height: 7.0.s),
                  Container(
                    width: 140.0.s,
                    height: 16.0.s,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(8.0.s),
                    ),
                  ),
                  SizedBox(height: 20.0.s),
                  Container(
                    width: 156.0.s,
                    height: 40.0.s,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12.0.s),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
