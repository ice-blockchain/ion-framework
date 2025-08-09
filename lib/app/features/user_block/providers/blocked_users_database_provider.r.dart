// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user_block/model/database/block_user_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'blocked_users_database_provider.r.g.dart';

@riverpod
BlockUserDatabase blockedUsersDatabase(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final database = BlockUserDatabase('test');

  onLogout(ref, database.close);

  return database;
}
