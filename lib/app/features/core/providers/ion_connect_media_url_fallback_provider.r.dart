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
class IonConnectMediaUrlFallback extends _$IonConnectMediaUrlFallback {
  @override
  Map<String, String> build() => {};

  /// A map of pubkeys to failed assets hosts
  final Map<String, Set<String>> _failedHosts = {};

  /// A map of pubkeys to Futures with identity pubkey relays (extra fallback)
  ///
  /// Storing Future instead of the result to avoid fetching the same relays multiple times
  /// in case of multiple simultaneous requests for the same author.
  final Map<String, Future<List<String>?>> _identityRelays = {};

  Future<String?> generateFallback(String initialAssetUrl, {required String authorPubkey}) async {
    if (!isIonMediaUrl(initialAssetUrl)) {
      return null;
    }

    final currentFallbackUrl = state[initialAssetUrl];

    // Add the current asset URL host to the failed hosts to avoid retrying
    // the same host in the future.
    _failedHosts
        .putIfAbsent(authorPubkey, () => {})
        .add(Uri.parse(currentFallbackUrl ?? initialAssetUrl).host);

    // First trying to get a fallback URL from the cached user relays.
    // If that fails, we try to get the fresh relays from the identity.
    final fallbackUrl = await _getFallbackUrl(
          initialAssetUrl,
          userRelays: await _getCachedUserRelays(authorPubkey),
          authorPubkey: authorPubkey,
        ) ??
        await _getFallbackUrl(
          initialAssetUrl,
          userRelays: await _getIdentityUserRelays(authorPubkey),
          authorPubkey: authorPubkey,
        );

    if (fallbackUrl != null) {
      state = {...state, initialAssetUrl: fallbackUrl};
      return fallbackUrl;
    }

    return null;
  }

  Future<List<String>?> _getIdentityUserRelays(String authorPubkey) async {
    return _identityRelays.putIfAbsent(
      authorPubkey,
      () => ref.read(userRelaysManagerProvider.notifier).fetchRelaysFromIdentity(
        [authorPubkey],
      ).then((entities) => entities.firstOrNull?.urls),
    );
  }

  Future<List<String>?> _getCachedUserRelays(String authorPubkey) async {
    final userRelayEntities =
        await ref.read(userRelaysManagerProvider.notifier).fetchReachableRelays([authorPubkey]);

    return userRelayEntities.firstOrNull?.urls;
  }

  Future<String?> _getFallbackUrl(
    String initialAssetUrl, {
    required List<String>? userRelays,
    required String authorPubkey,
  }) async {
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
