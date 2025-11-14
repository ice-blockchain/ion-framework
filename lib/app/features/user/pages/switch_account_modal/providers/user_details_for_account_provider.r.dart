// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_details_for_account_provider.r.g.dart';

@riverpod
Future<UserDetails?> userDetailsForAccount(
  Ref ref,
  String identityKeyName,
) async {
  try {
    final ionIdentity = await ref.watch(ionIdentityProvider.future);
    final ionIdentityClient = ionIdentity(username: identityKeyName);
    return await ionIdentityClient.users.currentUserDetails();
  } catch (_) {
    return null;
  }
}
