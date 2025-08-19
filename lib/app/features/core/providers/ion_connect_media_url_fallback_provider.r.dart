// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/utils/url.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_media_url_fallback_provider.r.g.dart';

/// A provider that manages fallback URLs for ION Connect media.
///
/// When a media URL fails to load, this provider replaces it with
/// a fallback URL using one of the user's available relays.
@Riverpod(keepAlive: true)
class IONConnectMediaUrlFallback extends _$IONConnectMediaUrlFallback {
  @override
  Map<String, String> build() => {};

  /// A map of pubkeys to failed assets hosts
  final Map<String, Set<String>> _failedHosts = {};

  /// A map of pubkeys to Futures with updated pubkey relays (extra fallback)
  final Map<String, List<Future<List<String>>>> _updatedRelays = {};

  Future<String?> generateFallback(String initialAssetUrl, {required String authorPubkey}) async {
    if (!isNetworkUrl(initialAssetUrl)) {
      return null;
    }

    final currentFallbackUrl = state[initialAssetUrl];

    _failedHosts
        .putIfAbsent(authorPubkey, () => {})
        .add(Uri.parse(currentFallbackUrl ?? initialAssetUrl).host);

    final fallbackUrl =
        await _getFallbackUrlFromAuthorRelays(initialAssetUrl, authorPubkey: authorPubkey);

    if (fallbackUrl != null) {
      state = {...state, initialAssetUrl: fallbackUrl};
      return fallbackUrl;
    }

    // Extra step - if all current author relays have failed
    // trying to refetch the relays from identity
    return null;
  }

  Future<String?> _getFallbackUrlFromAuthorRelays(
    String initialAssetUrl, {
    required String authorPubkey,
  }) async {
    final userRelayEntities =
        await ref.read(userRelaysManagerProvider.notifier).fetchReachableRelays([authorPubkey]);

    final userRelays = userRelayEntities.firstOrNull?.urls;

    if (userRelays == null || userRelays.isEmpty) {
      return null;
    }

    final fallbackHosts = userRelays
        .map((relayUrl) => Uri.parse(relayUrl).host)
        .toSet()
        .difference(_failedHosts[authorPubkey] ?? {});

    if (fallbackHosts.isEmpty) {
      return null;
    }

    return Uri.parse(initialAssetUrl).replace(host: fallbackHosts.first).toString();
  }
}
