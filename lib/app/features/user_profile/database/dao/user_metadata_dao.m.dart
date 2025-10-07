// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_metadata_dao.m.g.dart';

@riverpod
UserMetadataDao userMetadataDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return UserMetadataDao();
}

class UserMetadataDao {
  Future<UserMetadataEntity?> get(String masterPubkey) async {
    return null;
  }
}
