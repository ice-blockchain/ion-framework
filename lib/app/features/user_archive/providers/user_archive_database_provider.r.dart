// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user_archive/model/database/user_archive_database.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_archive_database_provider.r.g.dart';

@riverpod
UserArchiveDatabase userArchiveDatabase(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  final pubkey = ref.watch(currentPubkeySelectorProvider);

  if (pubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final database = UserArchiveDatabase(pubkey);

  onLogout(ref, database.close);
  onUserSwitch(ref, database.close);

  return database;
}
