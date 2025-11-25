// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user_block/model/database/block_user_database.m.dart';
import 'package:ion/app/services/database/database_manager_service.r.dart';
import 'package:ion/app/services/database/database_ready_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blocked_users_database_provider.r.g.dart';

@riverpod
BlockUserDatabase blockedUsersDatabase(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final pubkey = ref.watch(databasesReadyPubkeyProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final manager = ref.watch(databaseManagerServiceProvider);
  final database = manager.getBlockUserDatabase(pubkey);

  if (database == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  onLogout(ref, () => unawaited(manager.closeBlockUserDatabase()));
  onUserSwitch(ref, () => unawaited(manager.closeBlockUserDatabase()));

  return database;
}
