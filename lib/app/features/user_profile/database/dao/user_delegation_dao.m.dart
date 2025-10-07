// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_delegation_dao.m.g.dart';

@riverpod
UserDelegationDao userDelegationDao(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  return UserDelegationDao();
}

class UserDelegationDao {
  Future<UserDelegationEntity?> get(String masterPubkey) async {
    return null;
  }
}
