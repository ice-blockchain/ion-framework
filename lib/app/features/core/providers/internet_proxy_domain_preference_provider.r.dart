// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/core/providers/proxy_domains_provider.r.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'internet_proxy_domain_preference_provider.r.g.dart';

/// Stores the currently working proxy *domain* for internet reachability checks.
///
/// This is a global preference (not keyed per IP), because the proxy domains are
/// expected to work for any API / connectivity check.
///
/// If the saved domain is no longer present in [proxyDomainsProvider], it is cleared.
@riverpod
class InternetProxyDomainPreference extends _$InternetProxyDomainPreference {
  static const _prefKey = 'internet_proxy_domain';

  @override
  String? build() {
    final storage = ref.watch(localStorageProvider);
    final allowedDomains = ref.watch(proxyDomainsProvider);

    final saved = storage.getString(_prefKey);
    if (saved == null || saved.trim().isEmpty) return null;

    final domain = saved.trim();

    if (!allowedDomains.contains(domain)) {
      // List changed or value is invalid -> clear.
      unawaited(storage.remove(_prefKey));
      return null;
    }

    return domain;
  }

  /// Persists the preferred proxy *domain* for internet reachability checks.
  ///
  /// If [domain] is `null`, empty, or not present in [proxyDomainsProvider], the
  /// stored value is cleared.
  FutureOr<void> persistPreferredProxyDomain(String? domain) async {
    final storage = ref.read(localStorageProvider);

    final normalized = domain?.trim();
    final allowedDomains = ref.read(proxyDomainsProvider);

    // Don't persist unknown domains; clear instead.
    if (normalized == null || normalized.isEmpty || !allowedDomains.contains(normalized)) {
      await storage.remove(_prefKey);
      state = null;
      return;
    }

    await storage.setString(_prefKey, normalized);
    state = normalized;
  }
}
