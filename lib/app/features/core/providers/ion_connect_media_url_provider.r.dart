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
/// We first try CDN URL, if that fails
/// we try the original URL, and if that also fails
/// we generate fallback URL using available media author's relays.
@Riverpod(keepAlive: true)
class IonConnectMediaUrl extends _$IonConnectMediaUrl {
  @override
  String build(String url) {
    if (!isNetworkUrl(url)) {
      return url;
    }

    final cdnUrl = ref.watch(ionConnectCdnUrlProvider(url));
    final fallbackUrl = ref.watch(ionConnectMediaUrlFallbackProvider.select((state) => state[url]));

    return fallbackUrl ?? cdnUrl;
  }

  Future<bool> generateFallback({required String authorPubkey}) async {
    final currentFallback =
        ref.read(ionConnectMediaUrlFallbackProvider.select((state) => state[url]));
    if (currentFallback == null && state != url) {
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
    final source = Uri.parse(url);
    return cdnBase.resolve(source.path).toString();
  } catch (error, stackTrace) {
    Logger.error(error, stackTrace: stackTrace, message: 'Failed to use CDN URL for $url');
    return url;
  }
}
