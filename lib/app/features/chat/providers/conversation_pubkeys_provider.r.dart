// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_pubkeys_provider.r.g.dart';

@riverpod
class ConversationPubkeys extends _$ConversationPubkeys {
  @override
  Future<void> build() async {}

  Future<Map<String, List<String>>> fetchUsersKeys(List<String> masterPubkeys) async {
    final usersKeys = <String, List<String>>{};

    final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);
    if (eventSigner == null) {
      throw EventSignerNotFoundException();
    }

    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    for (final masterPubkey in masterPubkeys) {
      final delegation = await ref.read(userDelegationProvider(masterPubkey).future);
      if (delegation == null) continue;

      final activeDevicePubkeys = delegation.data.activeDelegates().keys.toList();

      // Only add if the current user's device is not revoked or if it's not the current user
      final isCurrentUser = currentUserMasterPubkey == masterPubkey;
      final isCurrentDeviceActive = activeDevicePubkeys.contains(eventSigner.publicKey);

      if (!isCurrentUser || isCurrentDeviceActive) {
        usersKeys[masterPubkey] = activeDevicePubkeys;
      }
    }

    return usersKeys;
  }
}
