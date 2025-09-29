// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/user_block/model/database/block_user_database.m.dart';
import 'package:ion/app/features/user_block/model/entities/blocked_user_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_blocked_users_handler.r.g.dart';

class EncryptedBlockedUserHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedBlockedUserHandler(this.blockEventDao, this.unblockEventDao);

  final BlockEventDao blockEventDao;
  final UnblockEventDao unblockEventDao;

  @override
  bool canHandle({required IonConnectGiftWrapEntity entity}) {
    return entity.data.kinds.containsDeep([
      BlockedUserEntity.kind.toString(),
    ]);
  }

  @override
  Future<EventReference?> handle(EventMessage rumor) async {
    if (rumor.kind == BlockedUserEntity.kind) {
      final entity = BlockedUserEntity.fromEventMessage(rumor);
      await _blockUser(rumor);
      return entity.toEventReference();
    } else if (rumor.kind == DeletionRequestEntity.kind) {
      final entity = DeletionRequestEntity.fromEventMessage(rumor);
      await _unblockUser(rumor);
      return entity.toEventReference();
    }
    return null;
  }

  Future<void> _blockUser(EventMessage rumor) async {
    await blockEventDao.add(rumor);
  }

  Future<void> _unblockUser(EventMessage rumor) async {
    final eventsToDelete = DeletionRequest.fromEventMessage(rumor).events;

    final eventToDeleteReferences =
        eventsToDelete.whereType<EventToDelete>().map((event) => event.eventReference).toList();

    if (eventToDeleteReferences.isEmpty) return;

    // Use Future.wait for concurrent async operations
    await Future.wait(
      eventToDeleteReferences.map(unblockEventDao.add),
    );
  }
}

@riverpod
EncryptedBlockedUserHandler encryptedBlockedUserHandler(Ref ref) {
  return EncryptedBlockedUserHandler(
    ref.watch(blockEventDaoProvider),
    ref.watch(unblockEventDaoProvider),
  );
}
