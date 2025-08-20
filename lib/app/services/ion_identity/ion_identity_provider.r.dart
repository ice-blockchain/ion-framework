// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/core/providers/internet_connection_checker_provider.r.dart';
import 'package:ion/app/services/http_client/connectivity_trigger_interceptor.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_identity_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<Raw<IONIdentity>> ionIdentity(Ref ref) async {
  final env = ref.watch(envProvider.notifier);

  final appId = env.get<String>(
    Platform.isAndroid ? EnvVariable.ION_ANDROID_APP_ID : EnvVariable.ION_IOS_APP_ID,
  );

  final logIonIdentityClient =
      ref.read(featureFlagsProvider.notifier).get(LoggerFeatureFlag.logIonIdentityClient);

  final baseLogger = logIonIdentityClient ? Logger.talkerDioLogger : null;
  final config = IONIdentityConfig(
    appId: appId,
    origin: env.get(EnvVariable.ION_ORIGIN),
    interceptors: [
      if (baseLogger != null) baseLogger,
      ConnectivitySideEffectInterceptor(
        internetConnectionChecker: ref.watch(internetConnectionCheckerProvider),
      ),
    ],
  );

  final ionClient = IONIdentity.createDefault(config: config);
  await ionClient.init();

  ref.onDispose(ionClient.dispose);

  return ionClient;
}
