// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user_block/model/database/block_user_database.m.dart';
import 'package:ion/app/features/user_block/model/entities/blocked_user_entity.f.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_user_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'block_list_notifier.r.g.dart';

@riverpod
class CurrentUserBlockListNotifier extends _$CurrentUserBlockListNotifier {
  @override
  Future<List<BlockedUserEntity>> build() async {
    final keepAlive = ref.keepAlive();
    onLogout(ref, keepAlive.close);

    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final blockEventDao = ref.watch(blockEventDaoProvider);

    final subscription =
        blockEventDao.watchBlockedUsersEvents(currentUserMasterPubkey).listen((blockEvents) {
      final entities = blockEvents.map(BlockedUserEntity.fromEventMessage).toList();

      // Ensure unique entities based on blocked master pubkey, this can happen
      // if multiple block events are received for the same blocked user
      final uniqueEntities = <String, BlockedUserEntity>{};
      for (final entity in entities) {
        final pubkey = entity.data.blockedMasterPubkeys.single;
        uniqueEntities[pubkey] = entity;
      }

      state = AsyncValue.data(uniqueEntities.values.toList());
    });

    ref.onDispose(subscription.cancel);

    return [];
  }
}

@riverpod
class CurrentUserBlockedByListNotifier extends _$CurrentUserBlockedByListNotifier {
  @override
  Future<List<BlockedUserEntity>> build() async {
    keepAliveWhenAuthenticated(ref);
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentUserMasterPubkey == null) {
      return [];
    }

    final blockEventDao = ref.watch(blockEventDaoProvider);

    final initialEvents = await blockEventDao.getBlockedByUsersEvents(currentUserMasterPubkey);
    final initialEntities = initialEvents.map(BlockedUserEntity.fromEventMessage);

    final subscription =
        blockEventDao.watchBlockedByUsersEvents(currentUserMasterPubkey).listen((events) {
      final entities = events.map(BlockedUserEntity.fromEventMessage);
      state = AsyncValue.data(entities.toList());
    });

    ref.onDispose(subscription.cancel);

    return initialEntities.toList();
  }
}

@riverpod
class IsBlockedNotifier extends _$IsBlockedNotifier {
  @override
  Future<bool> build(String masterPubkey) async {
    final keepAlive = ref.keepAlive();
    onLogout(ref, keepAlive.close);

    final blockedUser = ref.watch(blockedUserWatchProvider(masterPubkey)).valueOrNull;

    return blockedUser != null && blockedUser.isBlocked;
  }
}

@riverpod
class IsBlockedByNotifier extends _$IsBlockedByNotifier {
  @override
  Future<bool> build(String masterPubkey) async {
    final keepAlive = ref.keepAlive();
    onLogout(ref, keepAlive.close);

    final blockedByList = await ref.watch(currentUserBlockedByListNotifierProvider.future);
    return blockedByList.any((entity) => entity.masterPubkey == masterPubkey);
  }
}

@riverpod
class IsBlockedOrBlockedByNotifier extends _$IsBlockedOrBlockedByNotifier {
  @override
  Future<bool> build(String pubkey) async {
    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(pubkey));
    if (isCurrentUserProfile) {
      return false;
    }

    final (isBlocked, isBlockedBy) = await (
      ref.watch(isBlockedNotifierProvider(pubkey).future),
      ref.watch(isBlockedByNotifierProvider(pubkey).future),
    ).wait;

    return isBlocked || isBlockedBy;
  }
}

@riverpod
bool isEntityBlockedOrBlockedBy(Ref ref, IonConnectEntity entity) {
  final isUserBlocked =
      ref.watch(blockedUserWatchProvider(entity.masterPubkey)).valueOrNull?.isBlocked ?? false;
  final blockedByList = ref.watch(currentUserBlockedByListNotifierProvider).valueOrNull ?? [];
  if (isUserBlocked ||
      blockedByList.any((bEntity) => bEntity.masterPubkey == entity.masterPubkey)) {
    return true;
  }
  if (entity is ModifiablePostEntity && entity.data.quotedEvent != null) {
    final quotedEntity = ref.watch(
      ionConnectInMemoryEntityProvider(
        eventReference: entity.data.quotedEvent!.eventReference,
      ),
    );
    if (quotedEntity != null) {
      return ref.watch(isEntityBlockedOrBlockedByProvider(quotedEntity));
    }
  } else if (entity is GenericRepostEntity) {
    final childEntity = ref.watch(
      ionConnectSyncEntityProvider(eventReference: entity.data.eventReference),
    );
    if (childEntity != null) {
      return ref.watch(isEntityBlockedOrBlockedByProvider(childEntity));
    }
  }

  return false;
}

@riverpod
Iterable<String> blockedUsersPubkeysSelector(Ref ref) =>
    ref
        .watch(currentUserBlockListNotifierProvider)
        .valueOrNull
        ?.map((blockUser) => blockUser.data.blockedMasterPubkeys)
        .expand((pubkey) => pubkey) ??
    [];
