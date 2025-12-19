// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/mute_set.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user_mute/model/database/user_mute_database.m.dart';
import 'package:ion/app/features/user_mute/model/entities/user_mute_entity.f.dart';
import 'package:ion/app/features/user_mute/providers/user_mute_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'muted_users_notifier.r.g.dart';

@riverpod
Future<MuteUserService> muteUserService(Ref ref) async {
  keepAliveWhenAuthenticated(ref);
  return MuteUserService(
    userMuteService: await ref.watch(userMuteServiceProvider.future),
    currentUserMasterPubkey: ref.watch(currentPubkeySelectorProvider),
    mutedUsersMasterPubkeys: await ref.watch(mutedUsersProvider.future),
  );
}

class MuteUserService {
  MuteUserService({
    required this.userMuteService,
    required this.currentUserMasterPubkey,
    required this.mutedUsersMasterPubkeys,
  });

  final UserMuteService userMuteService;
  final String? currentUserMasterPubkey;
  final List<String> mutedUsersMasterPubkeys;

  Future<void> toggleMutedUser(String masterPubkey) async {
    final mutedUsersList = List<String>.from(mutedUsersMasterPubkeys);

    if (mutedUsersList.contains(masterPubkey)) {
      mutedUsersList.remove(masterPubkey);
    } else {
      mutedUsersList.add(masterPubkey);
    }

    await userMuteService.sendUserMuteEvent(mutedUsersList);
  }
}

@riverpod
MuteSetEntity? cachedMuteSet(Ref ref) {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  return ref.watch(
    ionConnectSyncEntityProvider(
      eventReference: ReplaceableEventReference(
        kind: MuteSetEntity.kind,
        masterPubkey: currentUserMasterPubkey,
        dTag: MuteSetType.notInterested.dTagName,
      ),
    ),
  ) as MuteSetEntity?;
}

@riverpod
Stream<List<String>> mutedUsers(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final mutedUsersEvent = ref.watch(userMuteEventDaoProvider).watchLatestMuteEvent();

  return mutedUsersEvent.map((event) {
    if (event == null) {
      return <String>[];
    }

    final entity = UserMuteEntity.fromEventMessage(event);
    return entity.data.mutedMasterPubkeys;
  });
}

@riverpod
bool isUserMuted(Ref ref, String masterPubkey) {
  final mutedPubkeys = ref.watch(mutedUsersProvider).valueOrNull ?? [];

  return mutedPubkeys.contains(masterPubkey);
}
