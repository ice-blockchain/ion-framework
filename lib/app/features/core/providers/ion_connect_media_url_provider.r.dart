// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_failed_hosts_provider.m.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_fallback_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/url.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_media_url_provider.r.g.dart';

String _buildCdnUrl(String cdnBaseUrl, String url) {
  final cdnBase = Uri.parse(cdnBaseUrl);
  final filePath = Uri.parse(url).pathSegments.last;
  return cdnBase.replace(pathSegments: [...cdnBase.pathSegments, filePath]).toString();
}

/// A provider that resolves ION Connect media URLs.
///
/// We first try the CDN URL.
/// If that fails, we try the original URL.
/// If that also fails, we generate a fallback URL using the media author's available relays.
@Riverpod(keepAlive: true)
class IonConnectMediaUrl extends _$IonConnectMediaUrl {
  @override
  String build(String url) {
    if (!isIonMediaUrl(url)) return url;

    final fallbackUrl = ref.watch(ionConnectMediaUrlFallbackProvider.select((state) => state[url]));

    if (fallbackUrl != null) return fallbackUrl;

    return ref.watch(ionConnectCdnUrlProvider(url));
  }

  Future<bool> generateFallback({required String authorPubkey}) async {
    final currentFallback =
        ref.read(ionConnectMediaUrlFallbackProvider.select((state) => state[url]));
    if (currentFallback == null && state != url) {
      // This is for the case when we first try CDN and in case of a failure, we're trying the original URL.
      // Also remembering that CDN doesn't work.
      ref.read(failedMediaHostsProvider.notifier).addFailedHost(Uri.parse(state).host);
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

/// Resolves the CDN URL for a given ION Connect media URL.
///
/// If the CDN host is marked as failed, it returns the original URL.
@riverpod
String ionConnectCdnUrl(Ref ref, String url) {
  final config = ref.watch(feedConfigProvider).valueOrNull;
  final failedMediaHosts = ref.watch(failedMediaHostsProvider);
  if (config == null) return url;
  try {
    final cdnHost = Uri.parse(config.cdnBaseUrl).host;
    if (failedMediaHosts.contains(FailedMediaHost(host: cdnHost))) return url;
    return _buildCdnUrl(config.cdnBaseUrl, url);
  } catch (error, stackTrace) {
    Logger.error(error, stackTrace: stackTrace, message: 'Failed to use CDN URL for $url');
    return url;
  }
}

/// Resolved CDN URL for share/og:image. Returns null when [imageUrl] is null or empty.
@riverpod
Future<String?> resolvedShareImageUrl(Ref ref, String? imageUrl) async {
  if (imageUrl == null || imageUrl.isEmpty) return null;
  if (!isIonMediaUrl(imageUrl)) return imageUrl;
  final config = await ref.read(feedConfigProvider.future);
  try {
    return _buildCdnUrl(config.cdnBaseUrl, imageUrl);
  } catch (error, stackTrace) {
    Logger.error(error, stackTrace: stackTrace, message: 'Failed to use CDN URL for $imageUrl');
    return imageUrl;
  }
}
