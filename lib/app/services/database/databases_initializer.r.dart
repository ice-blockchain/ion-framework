// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/services/database/database_manager_service.r.dart';
import 'package:ion/app/services/database/database_ready_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'databases_initializer.r.g.dart';

@Riverpod(keepAlive: true)
class DatabasesInitializer extends _$DatabasesInitializer {
  @override
  Future<void> build() async {
    final pubkey = ref.watch(currentPubkeySelectorProvider);

    if (pubkey == null) {
      ref.read(databasesReadyNotifierProvider.notifier).notReady();
      return;
    }

    final appGroup = Platform.isIOS
        ? ref.watch(envProvider.notifier).get<String>(EnvVariable.FOUNDATION_APP_GROUP)
        : null;

    final manager = ref.watch(databaseManagerServiceProvider);

    await manager.initializeDatabases(
      pubkey: pubkey,
      appGroup: appGroup,
    );

    ref.read(databasesReadyNotifierProvider.notifier).ready();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    ref.read(userSwitchInProgressProvider.notifier).completeSwitching();
  }
}
