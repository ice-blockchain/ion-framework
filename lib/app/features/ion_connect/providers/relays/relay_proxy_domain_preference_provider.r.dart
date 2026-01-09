// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/ion_connect/providers/relays/relay_proxy_domains_provider.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_proxy_domain_preference_provider.r.g.dart';

/// Stores the currently working relay proxy *domain* for a given logical relay URL.
///
/// Keyed by the logical relay URL (e.g. `wss://192.168.1.1:4443`) but persists only
/// the chosen proxy *domain* (e.g. `relays1.ion-connect.identity.io`), so we can
/// rebuild connect candidates as:
/// `wss://<sha16(ip)>.<domain>:<same_port_as_logical>`
///
/// If the saved domain is no longer present in [relaysProxyDomainsProvider], it is cleared.
@riverpod
class RelayProxyDomainPreference extends _$RelayProxyDomainPreference {
  static const _prefKeyPrefix = 'relay_proxy_domain';

  @override
  String? build(String logicalRelayUrl) {
    final prefs = ref.watch(currentUserPreferencesServiceProvider);
    if (prefs == null) return null;

    final allowedDomains = ref.watch(relaysProxyDomainsProvider);

    final saved = prefs.getValue<String>(_prefKeyFor(logicalRelayUrl));
    if (saved == null || saved.trim().isEmpty) return null;

    final domain = saved.trim();

    if (!allowedDomains.contains(domain)) {
      // List changed or value is invalid -> clear.
      unawaited(prefs.remove(_prefKeyFor(logicalRelayUrl)));
      return null;
    }

    return domain;
  }

  /// Persists the preferred proxy *domain* for this logical relay URL.
  ///
  /// If [domain] is `null`, the stored value is cleared.
  FutureOr<void> persistPreferredProxyDomain(String? domain) async {
    final prefs = ref.read(currentUserPreferencesServiceProvider);
    if (prefs == null) return;

    final key = _prefKeyFor(logicalRelayUrl);

    final normalized = domain?.trim();
    final allowedDomains = ref.read(relaysProxyDomainsProvider);
    // Don't persist unknown domains; clear instead.
    if (normalized == null || !allowedDomains.contains(normalized)) {
      await prefs.remove(key);
      state = null;
      return;
    }

    await prefs.setValue<String>(key, normalized);
    state = normalized;
  }

  String _prefKeyFor(String logicalRelayUrl) {
    return '$_prefKeyPrefix:$logicalRelayUrl';
  }
}
