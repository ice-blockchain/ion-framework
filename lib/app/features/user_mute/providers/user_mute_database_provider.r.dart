// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user_mute/model/database/user_mute_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_mute_database_provider.r.g.dart';

@riverpod
UserMuteDatabase userMuteDatabase(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final database = UserMuteDatabase(pubkey);

  onLogout(ref, database.close);
  onUserSwitch(ref, database.close);

  return database;
}
