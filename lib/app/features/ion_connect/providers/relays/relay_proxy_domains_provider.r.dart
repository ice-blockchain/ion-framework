// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:convert/convert.dart' as convert;
import 'package:cryptography/dart.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_proxy_domain_preference_provider.r.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_proxy_domains_provider.r.g.dart';

/// Proxy domains used to reach Nostr relays when direct IP connectivity is
/// unavailable or unreliable.
@riverpod
List<String> relaysProxyDomains(Ref ref) {
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
/// 3) Remaining proxy URIs built as `wss://<sha256(ip)[0:16]>.443`
@riverpod
List<Uri> relayConnectUris(Ref ref, String logicalRelayUrl) {
  final logicalUri = Uri.parse(logicalRelayUrl);
  final ip = logicalUri.host;

  // If we can't extract an IP/host, fall back to the original URI only.
  if (ip.isEmpty) {
    return <Uri>[logicalUri];
  }

  final domains = ref.read(relaysProxyDomainsProvider);
  final preferredDomain = ref.read(relayProxyDomainPreferenceProvider(logicalRelayUrl));

  final hash = const DartSha256().hashSync(utf8.encode(ip));
  final hashHex = convert.hex.encode(hash.bytes);
  final normalizedIp = hashHex.substring(0, 16);

  Uri proxyUriForDomain(String domain) => Uri(
        scheme: logicalUri.scheme.isNotEmpty ? logicalUri.scheme : 'wss',
        host: '$normalizedIp.$domain',
        port: 443,
      );

  final candidates = <Uri>[];

  final preferred = preferredDomain?.trim();
  if (preferred != null && preferred.isNotEmpty) {
    candidates.add(proxyUriForDomain(preferred));
  }

  // Then try direct IP.
  candidates.add(logicalUri);

  // Then try the rest of proxy domains.
  for (final domain in domains) {
    if (preferred != null && preferred == domain) continue;
    candidates.add(proxyUriForDomain(domain));
  }

  return candidates;
}
