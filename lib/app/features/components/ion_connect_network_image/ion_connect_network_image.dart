// SPDX-License-Identifier: ice License 1.0

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_provider.r.dart';
import 'package:ion/app/services/file_cache/ion_cache_manager.dart';

class IonConnectNetworkImage extends HookConsumerWidget {
  IonConnectNetworkImage({
    required this.imageUrl,
    required this.authorPubkey,
    this.imageBuilder,
    this.progressIndicatorBuilder,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    BaseCacheManager? cacheManager,
    this.fit,
    this.errorWidget,
    this.placeholder,
    this.fadeInDuration,
    this.fadeOutDuration,
    this.borderRadius,
    super.key,
  }) : cacheManager = cacheManager ?? IONCacheManager.ionConnectNetworkImage;

  final String imageUrl;
  final String authorPubkey;
  final BaseCacheManager cacheManager;
  final ImageWidgetBuilder? imageBuilder;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final PlaceholderWidgetBuilder? placeholder;
  final BoxFit? fit;
  final FilterQuality filterQuality;
  final Alignment alignment;
  final double? width;
  final double? height;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcePath = ref.watch(ionConnectMediaUrlProvider(imageUrl));

    final cacheKey =
        useMemoized(() => IONCacheManager.getCacheKeyFromIonUrl(sourcePath), [sourcePath]);

    return IonNetworkImage(
      imageUrl: sourcePath,
      cacheKey: cacheKey,
      cacheManager: cacheManager,
      imageBuilder: imageBuilder,
      placeholder: placeholder,
      progressIndicatorBuilder: progressIndicatorBuilder,
      fit: fit,
      filterQuality: filterQuality,
      alignment: alignment,
      width: width,
      height: height,
      fadeInDuration: fadeInDuration ?? Duration.zero,
      fadeOutDuration: fadeOutDuration ?? Duration.zero,
      borderRadius: borderRadius,
      errorListener: (_) {
        if (ref.context.mounted) {
          ref
              .read(ionConnectMediaUrlProvider(imageUrl).notifier)
              .generateFallback(authorPubkey: authorPubkey);
        }
      },
    );
  }
}
