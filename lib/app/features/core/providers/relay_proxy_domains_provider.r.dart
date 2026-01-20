// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_proxy_domain_preference_provider.r.dart';
import 'package:ion/app/utils/proxy_host.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_proxy_domains_provider.r.g.dart';

/// Proxy domains used to reach Nostr relays when direct IP connectivity is
/// unavailable or unreliable.
@riverpod
List<String> relayProxyDomains(Ref ref) {
  final env = ref.watch(envProvider.notifier);
  final domainsRaw = env.get<String>(EnvVariable.RELAY_PROXY_DOMAINS);
  return domainsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

/// Returns a list of candidate relay connection URIs for a logical relay URL.
///
/// The logical relay URL is expected to be an IP-based websocket URL like:
/// `wss://192.168.1.1:4443`.
///
/// Candidates are returned in the following order:
/// 1) Preferred proxy URI (if saved for this logical relay)
/// 2) The original logical relay URI (direct IP)
/// 3) Remaining proxy URIs built as `wss://<sha256(ip)[0:16]>.domain:443`
@riverpod
List<Uri> relayConnectUris(Ref ref, String logicalRelayUrl) {
  final logicalUri = Uri.parse(logicalRelayUrl);
  final normalizedLogicalUri =
      (logicalUri.hasPort && logicalUri.port == 4443) ? logicalUri.replace(port: 443) : logicalUri;
  final ip = logicalUri.host;

  // If we can't extract an IP/host, fall back to the original URI only.
  if (ip.isEmpty) {
    return <Uri>[normalizedLogicalUri];
  }

  final domains = ref.read(relayProxyDomainsProvider);
  final preferredDomain = ref.read(relayProxyDomainPreferenceProvider(logicalRelayUrl));

  Uri proxyUriForDomain(String domain) => Uri(
        scheme: normalizedLogicalUri.scheme.isNotEmpty ? normalizedLogicalUri.scheme : 'wss',
        host: buildRelayProxyHostForIp(ip: ip, domain: domain),
        port: normalizedLogicalUri.hasPort ? normalizedLogicalUri.port : null,
      );

  final candidates = <Uri>[];

  final preferred = preferredDomain?.trim();
  if (preferred != null && preferred.isNotEmpty) {
    candidates.add(proxyUriForDomain(preferred));
  }

  // Then try direct IP.
  candidates.add(normalizedLogicalUri);

  // Then try the rest of proxy domains.
  for (final domain in domains) {
    if (preferred != null && preferred == domain) continue;
    candidates.add(proxyUriForDomain(domain));
  }

  return candidates;
}
