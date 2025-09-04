// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/badges/badge_award.f.dart';
import 'package:ion/app/features/user/model/badges/badge_definition.f.dart';
import 'package:ion/app/features/user/model/badges/profile_badges.f.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user_profile/database/dao/user_badge_info_dao.m.dart';
import 'package:ion/app/features/user_profile/database/dao/user_delegation_dao.m.dart';
import 'package:ion/app/features/user_profile/database/dao/user_metadata_dao.m.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_sync_provider.r.g.dart';

@riverpod
class UserProfileSync extends _$UserProfileSync {
  static const String localStorageKey = 'user_profile_last_sync';

  @override
  Future<void> build() async {
    final keepAlive = ref.keepAlive();
    onLogout(ref, keepAlive.close);

    final authState = await ref.watch(authProvider.future);
    if (!authState.isAuthenticated) return;

    final delegationComplete = await ref.watch(delegationCompleteProvider.future);
    if (!delegationComplete) return;
  }

  Future<void> syncUserProfile({
    bool forceSync = false,
    Set<String> masterPubkeys = const {},
  }) async {
    final masterPubkey = ref.read(currentPubkeySelectorProvider);

    if (masterPubkey == null) throw UserMasterPubkeyNotFoundException();

    final userMetadataDao = ref.read(userMetadataDaoProvider);

    final existingMasterPubkeys = await userMetadataDao.getExistingMasterPubkeys();

    final masterPubkeysDifference = masterPubkeys.difference(existingMasterPubkeys);

    final masterPubkeysToSync = Set<String>.from(existingMasterPubkeys)..addAll(masterPubkeys);

    final syncWindow =
        ref.read(envProvider.notifier).get<int>(EnvVariable.USER_METADATA_SYNC_MINUTES);

    final localStorage = await ref.read(localStorageAsyncProvider.future);

    final lastSyncTime = DateTime.tryParse(localStorage.getString(localStorageKey) ?? '');

    if (forceSync ||
        lastSyncTime == null ||
        masterPubkeysDifference.isNotEmpty ||
        lastSyncTime.isBefore(DateTime.now().subtract(Duration(minutes: syncWindow)))) {
      await _fetchUsersProfiles(ref, masterPubkeysToSync: masterPubkeysToSync);

      await localStorage.setString(localStorageKey, DateTime.now().toIso8601String());
    }
  }

  Future<void> _fetchUsersProfiles(
    Ref ref, {
    required Set<String> masterPubkeysToSync,
  }) async {
    final userBadgesDao = ref.read(userBadgeInfoDaoProvider);
    final userMetadataDao = ref.read(userMetadataDaoProvider);
    final userDelegationDao = ref.read(userDelegationDaoProvider);

    if (masterPubkeysToSync.isEmpty) return;

    final usersProfileEntities = await ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
          eventReferences: masterPubkeysToSync
              .map(
                (pubkey) =>
                    ReplaceableEventReference(masterPubkey: pubkey, kind: UserMetadataEntity.kind),
              )
              .toList(),
          search: SearchExtensions([
            GenericIncludeSearchExtension(
              forKind: UserMetadataEntity.kind,
              includeKind: UserDelegationEntity.kind,
            ),
            ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind),
          ]).toString(),
          cache: false,
        );

    final usersMetadata = usersProfileEntities.whereType<UserMetadataEntity>().toList();
    final usersDelegation = usersProfileEntities.whereType<UserDelegationEntity>().toList();
    final profileBadges = usersProfileEntities.whereType<ProfileBadgesEntity>().toList();
    final badgeDefinitions = usersProfileEntities.whereType<BadgeDefinitionEntity>().toList();
    final badgeAwards = usersProfileEntities.whereType<BadgeAwardEntity>().toList();

    await userMetadataDao.insertAll(usersMetadata);
    await userDelegationDao.insertAll(usersDelegation);
    await userBadgesDao.insertAllProfileBadges(profileBadges);
    await userBadgesDao.insertAllBadgeDefinitions(badgeDefinitions);
    await userBadgesDao.insertAllBadgeAwards(badgeAwards);
  }
}
