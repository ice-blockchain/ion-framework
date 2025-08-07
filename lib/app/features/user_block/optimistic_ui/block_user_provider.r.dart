// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/user_block/model/database/dao/block_event_dao.m.dart';
import 'package:ion/app/features/user_block/model/entities/blocked_user_entity.f.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_sync_strategy_provider.r.dart';
import 'package:ion/app/features/user_block/optimistic_ui/model/blocked_user.f.dart';
import 'package:ion/app/features/user_block/optimistic_ui/toggle_block_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'block_user_provider.r.g.dart';

@riverpod
Future<List<BlockedUser>> loadInitialBlockedUsers(Ref ref) async {
  final currentMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final blockEventDao = ref.watch(blockEventDaoProvider);
  final blockEvents = await blockEventDao.getBlockEvents(currentMasterPubkey);
  final blockEventEntities = blockEvents.map(BlockedUserEntity.fromEventMessage).toList();

  // Ensure unique entities based on blocked master pubkey, this can happen
  // if multiple block events are received for the same blocked user
  final uniqueEntities = <String, BlockedUserEntity>{};
  for (final entity in blockEventEntities) {
    final pubkey = entity.data.blockedMasterPubkeys.single;
    uniqueEntities[pubkey] = entity;
  }

  return Future.wait(
    uniqueEntities.values.toList().map((blockEntity) async {
      return BlockedUser(
        isBlocked: true,
        masterPubkey: blockEntity.data.blockedMasterPubkeys.single,
      );
    }),
  );
}

@riverpod
OptimisticOperationManager<BlockedUser> blockUserManager(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final strategy = ref.watch(blockSyncStrategyProvider);

  final manager = OptimisticOperationManager<BlockedUser>(
    syncCallback: strategy.send,
    onError: (_, __) async => true,
  );

  ref.onDispose(manager.dispose);

  return manager;
}

@riverpod
OptimisticService<BlockedUser> blockUserService(Ref ref) {
  final manager = ref.watch(blockUserManagerProvider);
  final service = OptimisticService<BlockedUser>(manager: manager);

  return service;
}

@riverpod
Stream<BlockedUser?> blockedUserWatch(Ref ref, String masterPubkey) {
  final service = ref.watch(blockUserServiceProvider)..initialize(loadInitialBlockedUsers(ref));

  return service.watch(masterPubkey);
}

@riverpod
class ToggleBlockNotifier extends _$ToggleBlockNotifier {
  @override
  void build() {}

  Future<void> toggle(String masterPubkey) async {
    final service = ref.read(blockUserServiceProvider);

    var current = ref.read(blockedUserWatchProvider(masterPubkey)).valueOrNull;

    current ??= BlockedUser(
      isBlocked: false,
      masterPubkey: masterPubkey,
    );

    await service.dispatch(ToggleBlockIntent(), current);
  }
}
