// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion_ads/ion_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:ion_ads/ion_ads.dart';

part 'ion_ad_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<AppodealIonAdsPlatform> ionAdClient(Ref ref) async {
  final platform = AppodealIonAdsPlatform();
  await platform.initialize(
    androidAppKey: const String.fromEnvironment('AD_APP_KEY_ANDROID'),
    iosAppKey: const String.fromEnvironment('AD_APP_KEY_IOS'),
    hasConsent: true,
    verbose: true,
  );

  return platform;
}
