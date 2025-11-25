// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/database/database_manager_service.r.dart';
import 'package:ion/app/services/database/databases_initializer.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_ready_notifier.r.g.dart';

@riverpod
String? databasesReadyPubkey(Ref ref) {
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    return null;
  }

  final initState = ref.watch(databasesInitializerProvider);

  if (initState.isLoading || initState.hasError) {
    return null;
  }

  final manager = ref.watch(databaseManagerServiceProvider);
  final database = manager.getWalletsDatabase(pubkey);

  return (database != null) ? pubkey : null;
}

@Riverpod(keepAlive: true)
class DatabasesReadyNotifier extends _$DatabasesReadyNotifier {
  @override
  bool build() => false;

  void ready() {
    state = true;
  }

  void notReady() {
    state = false;
  }
}
