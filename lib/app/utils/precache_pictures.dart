// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/image_path.dart';

class PreCachePicturesCacheManager {
  static const key = 'preCachePicturesCacheKey';

  static CacheManager instance = CacheManager(
    Config(
      key,
      maxNrOfCacheObjects: 1000,
      stalePeriod: const Duration(days: 60),
    ),
  );
}

Future<void> precachePictures(BuildContext context, Iterable<String> urls) async {
  try {
    await Future.wait(urls.map((url) => _precachePicture(context, url)));
  } catch (e, stackTrace) {
    Logger.error(e, stackTrace: stackTrace, message: 'Failed to precache pictures: $urls');
  }
}

Future<void> _precachePicture(BuildContext context, String url) async {
  unawaited(
    runZonedGuarded(
      () async {
        if (url.isSvg) {
          final loader = url.isNetworkSvg ? SvgNetworkLoader(url) : SvgAssetLoader(url);
          await svg.cache.putIfAbsent(
            loader.cacheKey(null),
            () => loader.loadBytes(null),
          );
        } else {
          // For other image types, let the cache manager handle everything.
          // .getSingleFile() will download the file if not cached, then return it.
          // We don't need the file itself, just the action of caching.

          try {
            await PreCachePicturesCacheManager.instance.getSingleFile(url);
          } catch (e) {
            Logger.warning('[Caught getSingleFile error] $url - Error: $e');
          }
          if (!context.mounted) return;

          final imageProvider = CachedNetworkImageProvider(
            url,
            cacheManager: PreCachePicturesCacheManager.instance,
            cacheKey: url,
          );
          await precacheImage(
            imageProvider,
            context,
            onError: (error, stackTrace) {
              Logger.warning('[Suppressed image loading error] while loading $url - Error: $error');
            },
          );
        }
      },
      (error, stack) {
        // Suppress all errors from reaching Sentry's global handler
        Logger.warning('[Suppressed precache error] while precaching $url - Error: $error, ');
      },
    ),
  );
}
