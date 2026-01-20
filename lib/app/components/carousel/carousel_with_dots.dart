// SPDX-License-Identifier: ice License 1.0

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';

class CarouselWithDots extends HookWidget {
  const CarouselWithDots({
    required this.items,
    this.height,
    this.aspectRatio,
    this.autoPlay = false,
    this.enlargeCenterPage = false,
    this.viewportFraction = 1.0,
    this.initialPage = 0,
    this.enableInfiniteScroll = true,
    this.reverse = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.autoPlayCurve = Curves.fastOutSlowIn,
    this.pauseAutoPlayOnTouch = true,
    this.pauseAutoPlayOnManualNavigate = true,
    this.pauseAutoPlayInFiniteScroll = true,
    this.clipBehavior = Clip.none,
    this.scrollDirection = Axis.horizontal,
    this.onPageChanged,
    this.dotsCount,
    this.dotsSpacing = 8.0,
    this.dotsSize = 9.0,
    this.dotsActiveSize = 18.0,
    this.dotsActiveHeight = 9.0,
    this.dotsColor,
    this.dotsActiveColor,
    this.dotsShape,
    this.dotsActiveShape,
    this.dotsDecorator,
    this.dotsPosition,
    super.key,
  });

  final List<Widget> items;
  final double? height;
  final double? aspectRatio;
  final bool autoPlay;
  final bool enlargeCenterPage;
  final double viewportFraction;
  final int initialPage;
  final bool enableInfiniteScroll;
  final bool reverse;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final Curve autoPlayCurve;
  final bool pauseAutoPlayOnTouch;
  final bool pauseAutoPlayOnManualNavigate;
  final bool pauseAutoPlayInFiniteScroll;
  final Clip clipBehavior;
  final Axis scrollDirection;
  final void Function(int index, CarouselPageChangedReason reason)? onPageChanged;

  // Dots indicator properties
  final int? dotsCount;
  final double dotsSpacing;
  final double dotsSize;
  final double dotsActiveSize;
  final double dotsActiveHeight;
  final Color? dotsColor;
  final Color? dotsActiveColor;
  final ShapeBorder? dotsShape;
  final ShapeBorder? dotsActiveShape;
  final DotsDecorator? dotsDecorator;
  final double? dotsPosition;

  @override
  Widget build(BuildContext context) {
    final currentPage = useState(initialPage);
    final carouselController = useMemoized(CarouselSliderController.new);

    final effectiveDotsCount = dotsCount ?? items.length;
    final effectiveDotsColor = dotsColor ?? context.theme.appColors.onTertiaryFill;
    final effectiveDotsActiveColor = dotsActiveColor ?? context.theme.appColors.primaryAccent;

    final defaultDotsDecorator = DotsDecorator(
      size: Size.square(dotsSize.s),
      activeSize: Size(dotsActiveSize.s, dotsActiveHeight.s),
      activeShape: dotsActiveShape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0.s),
          ),
      shape: dotsShape ?? const CircleBorder(),
      color: effectiveDotsColor,
      activeColor: effectiveDotsActiveColor,
      spacing: EdgeInsets.all(dotsSpacing.s),
    );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          carouselController: carouselController,
          options: CarouselOptions(
            height: height,
            aspectRatio: 343 / 120,
            viewportFraction: viewportFraction,
            initialPage: initialPage,
            enableInfiniteScroll: enableInfiniteScroll,
            reverse: reverse,
            autoPlay: autoPlay,
            autoPlayInterval: autoPlayInterval,
            autoPlayAnimationDuration: autoPlayAnimationDuration,
            autoPlayCurve: autoPlayCurve,
            pauseAutoPlayOnTouch: pauseAutoPlayOnTouch,
            pauseAutoPlayOnManualNavigate: pauseAutoPlayOnManualNavigate,
            pauseAutoPlayInFiniteScroll: pauseAutoPlayInFiniteScroll,
            enlargeCenterPage: enlargeCenterPage,
            clipBehavior: clipBehavior,
            scrollDirection: scrollDirection,
            onPageChanged: (int index, CarouselPageChangedReason reason) {
              currentPage.value = index;
              onPageChanged?.call(index, reason);
            },
          ),
          items: items,
        ),
        if (effectiveDotsCount > 1)
          PositionedDirectional(
            bottom: dotsPosition ?? 8.s,
            child: DotsIndicator(
              dotsCount: effectiveDotsCount,
              position: currentPage.value,
              decorator: dotsDecorator ?? defaultDotsDecorator,
            ),
          ),
      ],
    );
  }
}
