// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_social_profile_provider.r.g.dart';

@riverpod
Future<UpdateUserSocialProfileResponse> updateUserSocialProfile(
  Ref ref, {
  required UserSocialProfileData data,
}) async {
  final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);
  return ionIdentityClient.users.updateUserSocialProfile(data: data);
}

@riverpod
Future<UserSocialProfileData> currentUserSocialProfile(Ref ref) async {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);
  return ionIdentityClient.users.getUserSocialProfile(userIdOrMasterKey: currentPubkey);
}
