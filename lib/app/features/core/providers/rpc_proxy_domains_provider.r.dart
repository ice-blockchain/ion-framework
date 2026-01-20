// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/utils/proxy_host.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rpc_proxy_domains_provider.r.g.dart';

/// Proxy domains used to reach Binance RPCs when direct IP connectivity is
/// unavailable or unreliable.
@riverpod
List<String> rpcProxyDomains(Ref ref) {
  final env = ref.watch(envProvider.notifier);
  final domainsRaw = env.get<String>(EnvVariable.RPC_PROXY_DOMAINS);
  return domainsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

@riverpod
List<Uri> rpcProxyConnectUris(Ref ref) {
  final domains = ref.read(rpcProxyDomainsProvider);
  return domains.map((domain) => buildBscRpcProxyUri(domain: domain)).toList();
}
