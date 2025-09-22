// SPDX-License-Identifier: ice License 1.0

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/placeholder/ion_placeholder.dart';

class IonNetworkImage extends HookWidget {
  IonNetworkImage({
    required this.imageUrl,
    super.key,
    this.imageBuilder,
    this.progressIndicatorBuilder,
    this.fadeOutDuration = Duration.zero,
    this.fadeInDuration = Duration.zero,
    this.placeholderFadeInDuration = Duration.zero,
    this.width,
    this.height,
    this.fit,
    this.alignment,
    this.filterQuality,
    BaseCacheManager? cacheManager,
    this.placeholder,
    this.errorListener,
    this.errorWidget,
    this.borderRadius,
  }) : cacheManager = cacheManager ??
            CacheManager(
              Config(
                'ionNetworkImageCacheKey',
                maxNrOfCacheObjects: 1000,
                stalePeriod: const Duration(days: 60),
              ),
            );

  final String imageUrl;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final ValueChanged<Object>? errorListener;
  final PlaceholderWidgetBuilder? placeholder;
  final Duration fadeOutDuration;
  final Duration fadeInDuration;
  final Duration placeholderFadeInDuration;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment? alignment;
  final FilterQuality? filterQuality;
  final BaseCacheManager cacheManager;
  final ImageWidgetBuilder? imageBuilder;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (width ?? MediaQuery.sizeOf(context).width) * devicePixelRatio;
    final cacheHeight = height != null ? height! * devicePixelRatio : null;
    int? memCacheWidth;
    int? memCacheHeight;

    if (fit == BoxFit.fitWidth ||
        fit == BoxFit.cover ||
        fit == BoxFit.fill ||
        fit == BoxFit.fitHeight) {
      memCacheWidth = cacheHeight == null ? cacheWidth.toInt() : null;
      memCacheHeight = cacheHeight?.toInt();
    }
    if (fit == BoxFit.contain) {
      memCacheWidth = cacheWidth.toInt();
      memCacheHeight = cacheHeight?.toInt();
    }

    final fetchError = useRef<Object?>(null);
    // Use the full URL as cache key to avoid collisions (e.g., '/favicon.ico' across domains)
    final cacheKey = imageUrl;

    if (borderRadius != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              imageUrl,
              maxWidth: memCacheWidth,
              maxHeight: memCacheHeight,
              cacheKey: cacheKey,
            ),
            fit: fit,
          ),
        ),
        child: SizedBox(
          width: width,
          height: height,
        ),
      );
    }

    return CachedNetworkImage(
      key: Key("${imageUrl}_${cacheWidth.toInt()}x${cacheHeight?.toInt() ?? 'auto'}"),
      cacheKey: cacheKey,
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment ?? Alignment.center,
      filterQuality: filterQuality ?? FilterQuality.medium,
      placeholder: (context, url) {
        final error = fetchError.value;
        if (error != null) {
          // Once any error is observed, always render the error widget here
          // (avoids placeholder <-> error flicker across internal retries)
          return errorWidget?.call(context, url, error) ?? const IonPlaceholder();
        }
        return placeholder?.call(context, url) ??
            const IonPlaceholder(
              isPlaceholder: true,
            );
      },
      errorListener: (error) {
        fetchError.value = error;
        errorListener?.call(error);
      },
      errorWidget: errorWidget ?? (context, url, error) => const IonPlaceholder(),
      fadeOutDuration: fadeOutDuration,
      fadeInDuration: fadeInDuration,
      placeholderFadeInDuration: placeholderFadeInDuration,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      imageBuilder: imageBuilder,
      cacheManager: cacheManager,
      progressIndicatorBuilder: progressIndicatorBuilder,
    );
  }
}
