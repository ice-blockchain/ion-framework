// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client_example/providers/current_username_notifier.r.dart';
import 'package:ion_identity_client_example/providers/ion_identity_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_identity_client_provider.r.g.dart';

@riverpod
FutureOr<IONIdentityClient> ionIdentityClient(Ref ref) async {
  final currentUsername = ref.watch(currentUsernameNotifierProvider);
  final ionIdentity = await ref.read(ionIdentityProvider.future);
  return ionIdentity(username: currentUsername!);
}
