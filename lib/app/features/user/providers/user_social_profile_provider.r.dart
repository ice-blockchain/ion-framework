// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/user/providers/current_user_identity_provider.r.dart';
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

/// Retrieves a user's social profile data. Priority: masterPubkey > userId > current user.
/// Throws Exception if no valid user identifier is found.
@riverpod
Future<UserSocialProfileData> getUserSocialProfile(
  Ref ref, {
  String? masterPubkey,
  String? userId,
}) async {
  final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);

  if (masterPubkey != null && masterPubkey.isNotEmpty) {
    return ionIdentityClient.users.getUserSocialProfile(
      userIdOrMasterKey: masterPubkey,
    );
  }

  if (userId != null && userId.isNotEmpty) {
    return ionIdentityClient.users.getUserSocialProfile(
      userIdOrMasterKey: userId,
    );
  }

  final userIdentity = ref.watch(currentUserIdentityProvider).valueOrNull;
  final currentUserId = userIdentity?.userId;

  if (currentUserId == null || currentUserId.isEmpty) {
    throw const UserNotFoundException();
  }

  return ionIdentityClient.users.getUserSocialProfile(
    userIdOrMasterKey: currentUserId,
  );
}
