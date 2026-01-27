// SPDX-License-Identifier: ice License 1.0

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';

class CarouselDotsConfig {
  const CarouselDotsConfig({
    this.count,
    this.spacing = 8.0,
    this.size = 9.0,
    this.activeSize = 18.0,
    this.activeHeight = 9.0,
    this.color,
    this.activeColor,
    this.shape,
    this.activeShape,
    this.decorator,
    this.position,
  });

  final int? count;
  final double spacing;
  final double size;
  final double activeSize;
  final double activeHeight;
  final Color? color;
  final Color? activeColor;
  final ShapeBorder? shape;
  final ShapeBorder? activeShape;
  final DotsDecorator? decorator;
  final double? position;
}

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
    this.dotsConfig,
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

  // Dots indicator configuration
  final CarouselDotsConfig? dotsConfig;

  @override
  Widget build(BuildContext context) {
    final currentPage = useState(initialPage);
    final carouselController = useMemoized(CarouselSliderController.new);

    final dotsSpacing = dotsConfig?.spacing ?? 8.0;
    final dotsSize = dotsConfig?.size ?? 9.0;
    final dotsActiveSize = dotsConfig?.activeSize ?? 18.0;
    final dotsActiveHeight = dotsConfig?.activeHeight ?? 9.0;
    final effectiveDotsCount = dotsConfig?.count ?? items.length;
    final effectiveDotsColor = dotsConfig?.color ?? context.theme.appColors.onTertiaryFill;
    final effectiveDotsActiveColor =
        dotsConfig?.activeColor ?? context.theme.appColors.primaryAccent;
    final dotsShape = dotsConfig?.shape;
    final dotsActiveShape = dotsConfig?.activeShape;
    final dotsDecorator = dotsConfig?.decorator;
    final dotsPosition = dotsConfig?.position;

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
            bottom: dotsPosition ?? 8.0.s,
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
