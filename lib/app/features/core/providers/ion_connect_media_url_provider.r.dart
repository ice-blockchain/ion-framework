// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_fallback_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/url.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_media_url_provider.r.g.dart';

/// A provider that resolves ION Connect media URLs.
///
/// We first try the CDN URL.
/// If that fails, we try the original URL.
/// If that also fails, we generate a fallback URL using the media author's available relays.
@Riverpod(keepAlive: true)
class IonConnectMediaUrl extends _$IonConnectMediaUrl {
  @override
  String build(String url) {
    if (!isIonMediaUrl(url)) {
      return url;
    }

    final fallbackUrl = ref.watch(ionConnectMediaUrlFallbackProvider.select((state) => state[url]));

    if (fallbackUrl != null) {
      return fallbackUrl;
    }

    return ref.watch(ionConnectCdnUrlProvider(url));
  }

  Future<bool> generateFallback({required String authorPubkey}) async {
    final currentFallback =
        ref.read(ionConnectMediaUrlFallbackProvider.select((state) => state[url]));
    if (currentFallback == null && state != url) {
      // This is for the case when we first try CDN and in case of a failure, we're trying the original URL.
      state = url;
      return true;
    } else {
      final fallbackUrl = await ref
          .read(ionConnectMediaUrlFallbackProvider.notifier)
          .generateFallback(url, authorPubkey: authorPubkey);
      return fallbackUrl != null;
    }
  }
}

@riverpod
String ionConnectCdnUrl(Ref ref, String url) {
  final config = ref.watch(feedConfigProvider).valueOrNull;
  if (config == null) return url;
  try {
    final cdnBase = Uri.parse(config.cdnBaseUrl);
    final filePath = Uri.parse(url).pathSegments.last;
    return cdnBase.replace(pathSegments: [...cdnBase.pathSegments, filePath]).toString();
  } catch (error, stackTrace) {
    Logger.error(error, stackTrace: stackTrace, message: 'Failed to use CDN URL for $url');
    return url;
  }
}
