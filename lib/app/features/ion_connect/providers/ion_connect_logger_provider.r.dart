// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_logger_provider.r.g.dart';

@Riverpod(keepAlive: true)
IonConnectLogger? ionConnectLogger(Ref ref) {
  final logIonConnect = ref.read(featureFlagsProvider.notifier).get(
        LoggerFeatureFlag.logIonConnect,
      );

  return logIonConnect ? IonConnectLogger() : null;
}
