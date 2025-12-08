// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion_ads/ion_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_ad_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<AppodealIonAdsPlatform> ionAdClient(Ref ref) async {
  // used only first time when app is opened from closed state (cold start)
  final platform = AppodealIonAdsPlatform();
  await platform.initialize(
    androidAppKey: const String.fromEnvironment('AD_APP_KEY_ANDROID'),
    iosAppKey: const String.fromEnvironment('AD_APP_KEY_IOS'),
    hasConsent: true,
    verbose: true,
  );

  // final env = ref.watch(envProvider.notifier);
  // final config = IONSwapConfig(
  //     okxApiKey: env.get(EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_API_KEY),
  //     okxSignKey: env.get(EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_SIGN_KEY),

  return platform;
}
