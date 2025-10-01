// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
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

  Future<void> _fetchUsersProfiles(Ref ref, {required Set<String> masterPubkeysToSync}) async {
    if (masterPubkeysToSync.isEmpty) return;

    final userBadgesDao = ref.read(userBadgeInfoDaoProvider);
    final userMetadataDao = ref.read(userMetadataDaoProvider);
    final userDelegationDao = ref.read(userDelegationDaoProvider);

    // Helper to extract entities by type
    List<T> extractEntities<T>(List<dynamic> entities) => entities.whereType<T>().toList();

    // Common search extensions
    final searchExtensions = SearchExtensions([
      GenericIncludeSearchExtension(
        forKind: UserMetadataEntity.kind,
        includeKind: UserDelegationEntity.kind,
      ),
      ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind),
    ]).toString();

    // Fetch from read relays
    final entitiesFromReadRelay = await ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
          cache: false,
          eventReferences: masterPubkeysToSync
              .map(
                (pubkey) => ReplaceableEventReference(
                  masterPubkey: pubkey,
                  kind: UserMetadataEntity.kind,
                ),
              )
              .toList(),
          search: searchExtensions,
        );

    // Insert all fetched entities
    await Future.wait([
      userMetadataDao.insertAll(extractEntities<UserMetadataEntity>(entitiesFromReadRelay)),
      userDelegationDao.insertAll(extractEntities<UserDelegationEntity>(entitiesFromReadRelay)),
      userBadgesDao
          .insertAllProfileBadges(extractEntities<ProfileBadgesEntity>(entitiesFromReadRelay)),
      userBadgesDao
          .insertAllBadgeDefinitions(extractEntities<BadgeDefinitionEntity>(entitiesFromReadRelay)),
      userBadgesDao.insertAllBadgeAwards(extractEntities<BadgeAwardEntity>(entitiesFromReadRelay)),
    ]);

    // Find missing master pubkeys
    final fetchedMasterPubkeys = extractEntities<UserMetadataEntity>(entitiesFromReadRelay)
        .map((e) => e.masterPubkey)
        .toSet();
    final missingMasterPubkeys = masterPubkeysToSync.difference(fetchedMasterPubkeys);

    if (missingMasterPubkeys.isEmpty) return;

    // Try to fetch missing entities from write relays in parallel
    final entitiesFromWriteRelays = await Future.wait(
      missingMasterPubkeys.map((missingPubkey) {
        return ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
              cache: false,
              actionType: ActionType.write,
              actionSource: ActionSource.user(missingPubkey),
              eventReferences: [
                ReplaceableEventReference(
                  masterPubkey: missingPubkey,
                  kind: UserMetadataEntity.kind,
                ),
              ],
              search: searchExtensions,
            );
      }),
    );

    // Flatten the list of lists into a single list
    final entitiesFromWriteRelay = entitiesFromWriteRelays.expand((e) => e).toList();

    if (entitiesFromWriteRelay.isNotEmpty) {
      await Future.wait([
        userMetadataDao.insertAll(extractEntities<UserMetadataEntity>(entitiesFromWriteRelay)),
        userDelegationDao.insertAll(extractEntities<UserDelegationEntity>(entitiesFromWriteRelay)),
        userBadgesDao
            .insertAllProfileBadges(extractEntities<ProfileBadgesEntity>(entitiesFromWriteRelay)),
        userBadgesDao.insertAllBadgeDefinitions(
            extractEntities<BadgeDefinitionEntity>(entitiesFromWriteRelay)),
        userBadgesDao
            .insertAllBadgeAwards(extractEntities<BadgeAwardEntity>(entitiesFromWriteRelay)),
      ]);
    }
  }
}
