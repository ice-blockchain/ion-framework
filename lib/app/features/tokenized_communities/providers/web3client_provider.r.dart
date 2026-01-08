// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/services/bsc_rpc_failover_http_client.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/app/utils/url.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web3dart/web3dart.dart';

part 'web3client_provider.r.g.dart';

@riverpod
class BscRpcUrlPreference extends _$BscRpcUrlPreference {
  static const _prefKey = 'bsc_selected_rpc_url';

  @override
  Uri? build() {
    final prefs = ref.watch(currentUserPreferencesServiceProvider);
    if (prefs == null) return null;

    final rpcUris = ref.watch(bscRpcUrisProvider);

    final saved = prefs.getValue<String>(_prefKey);
    if (saved == null || saved.trim().isEmpty) return null;

    try {
      final parsed = Uri.parse(saved.trim());
      final existsInList = rpcUris.any((u) => u.toString() == parsed.toString());
      if (!existsInList) {
        // Env list changed; clear persisted preference.
        unawaited(prefs.remove(_prefKey));
        return null;
      }
      return parsed;
    } catch (_) {
      // Corrupt value; clear it.
      unawaited(prefs.remove(_prefKey));
      return null;
    }
  }

  /// Persists the currently working RPC URL.
  ///
  /// If [url] is `null`, the stored value is cleared.
  FutureOr<void> persistPreferredRpcUrl(String? url) async {
    final prefs = ref.read(currentUserPreferencesServiceProvider);
    if (prefs == null) return;

    if (url == null) {
      await prefs.remove(_prefKey);
      state = null;
      return;
    }

    await prefs.setValue<String>(_prefKey, url);
  }
}

@riverpod
List<Uri> bscRpcUris(Ref ref) {
  final env = ref.watch(envProvider.notifier);
  final urlsRaw = env.get<String>(EnvVariable.CRYPTOCURRENCIES_BSC_RPC_URLS);
  return parseUrlsString(urlsRaw);
}

@riverpod
Web3Client web3Client(Ref ref) {
  final rpcUris = ref.watch(bscRpcUrisProvider);
  if (rpcUris.isEmpty) {
    throw StateError(
      'No BSC RPC URLs configured. Provide CRYPTOCURRENCIES_BSC_RPC_URLS (comma-separated).',
    );
  }

  final preferred = ref.read(bscRpcUrlPreferenceProvider);
  final failoverHttpClient = BscRpcFailoverHttpClient(
    endpoints: rpcUris,
    initialPreferred: preferred,
    inner: http.Client(),
    persistPreferredRpcUrl: ref.read(bscRpcUrlPreferenceProvider.notifier).persistPreferredRpcUrl,
  );

  ref.onDispose(failoverHttpClient.close);

  final rpc = PreferredUrlJsonRpc(
    urlProvider: () => failoverHttpClient.currentUrl,
    client: failoverHttpClient,
  );

  return Web3Client.custom(rpc);
}
