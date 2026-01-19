// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/internet_proxy_domain_preference_provider.r.dart';
import 'package:ion/app/features/core/providers/proxy_domains_provider.r.dart';
import 'package:ion/app/features/core/services/internet_connection_checker.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'internet_connection_checker_provider.r.g.dart';

@Riverpod(keepAlive: true)
InternetConnectionChecker internetConnectionChecker(Ref ref) {
  const checkInterval = Duration(hours: 1);
  const checkNoInternetInterval = Duration(seconds: 10);
  const hosts = [
    InternetCheckOption(host: '1.1.1.1'), // Cloudflare
    InternetCheckOption(host: '8.8.8.8'), // Google
    InternetCheckOption(host: '9.9.9.9'), // Quad9
    InternetCheckOption(host: '77.88.8.8'), // Yandex
    InternetCheckOption(host: '64.6.64.6'), // Comodo
  ];
  final proxyDomains = ref.watch(proxyDomainsProvider);
  final preferredProxyDomain = ref.watch(internetProxyDomainPreferenceProvider);
  Logger.info(
    '[Internet] creating checker; interval=${checkInterval.inSeconds}s, hosts=${hosts.map((h) => h.host).toList()}, proxyDomains=$proxyDomains, preferredProxyDomain=$preferredProxyDomain',
  );
  return InternetConnectionChecker.createInstance(
    checkInterval: checkInterval,
    checkNoInternetInterval: checkNoInternetInterval,
    options: hosts,
    proxyDomains: proxyDomains,
    initialPreferredProxyDomain: preferredProxyDomain,
    persistPreferredProxyDomain:
        ref.read(internetProxyDomainPreferenceProvider.notifier).persistPreferredProxyDomain,
  );
}
