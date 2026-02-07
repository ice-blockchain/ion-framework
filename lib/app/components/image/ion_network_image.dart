// SPDX-License-Identifier: ice License 1.0

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/placeholder/ion_placeholder.dart';
import 'package:ion/app/services/file_cache/ion_cache_manager.dart';

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
    this.cacheKey,
  }) : cacheManager = cacheManager ?? IONCacheManager.ionNetworkImage;

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
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    final supportsResize = cacheManager is ImageCacheManager;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final layoutWidth = MediaQuery.sizeOf(context).width;

    final (memCacheWidth, memCacheHeight) = useMemoized(
      () {
        if (!supportsResize) return (null, null);
        final cacheWidth = (width ?? layoutWidth) * devicePixelRatio;
        final cacheHeight = height != null ? height! * devicePixelRatio : null;
        int? w;
        int? h;
        if (fit == BoxFit.fitWidth ||
            fit == BoxFit.cover ||
            fit == BoxFit.fill ||
            fit == BoxFit.fitHeight) {
          w = cacheHeight == null ? cacheWidth.toInt() : null;
          h = cacheHeight?.toInt();
        }
        if (fit == BoxFit.contain) {
          w = cacheWidth.toInt();
          h = cacheHeight?.toInt();
        }
        return (w, h);
      },
      [devicePixelRatio, layoutWidth, width, height, fit, cacheManager],
    );

    final fetchError = useRef<Object?>(null);

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
              cacheManager: cacheManager,
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
      key: supportsResize ? Key("${imageUrl}_${memCacheWidth}x${memCacheHeight ?? 'auto'}") : null,
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
