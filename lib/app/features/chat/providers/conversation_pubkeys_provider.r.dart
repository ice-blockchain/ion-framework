// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_pubkeys_provider.r.g.dart';

@riverpod
class ConversationPubkeys extends _$ConversationPubkeys {
  @override
  Future<void> build() async {}

  Future<Map<String, List<String>>> fetchUsersKeys(List<String> masterPubkeys) async {
    final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);

    if (eventSigner == null) {
      throw EventSignerNotFoundException();
    }

    final currentUserPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentUserPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final usersKeys = <String, List<String>>{};

    for (final masterPubkey in masterPubkeys) {
      final delegation = await ref.read(userDelegationProvider(masterPubkey).future);

      if (delegation == null) {
        continue;
      }

      final activeDelegates = delegation.data.delegates
          .where((delegate) => delegate.status == DelegationStatus.active)
          .toList();

      final pubkeys = activeDelegates.map((delegate) => delegate.pubkey).toList();

      // If this is the current user, ensure that the current device pubkey is
      // not revoked
      if (masterPubkey == currentUserPubkey && !pubkeys.contains(eventSigner.publicKey)) {
        throw UserDeviceRevokedException();
      }

      usersKeys.addAll({masterPubkey: pubkeys});
    }
    
    return usersKeys;
  }
}
