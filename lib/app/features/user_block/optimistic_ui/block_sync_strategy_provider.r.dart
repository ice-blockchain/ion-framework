// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/pubkey_tag.f.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/user_block/model/database/block_user_database.m.dart';
import 'package:ion/app/features/user_block/model/entities/blocked_user_entity.f.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_sync_strategy.dart';
import 'package:ion/app/features/user_block/optimistic_ui/model/blocked_user.f.dart';
import 'package:ion/app/services/ion_connect/ion_connect_gift_wrap_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_seal_service.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'block_sync_strategy_provider.r.g.dart';

@riverpod
SyncStrategy<BlockedUser> blockSyncStrategy(Ref ref) {
  final eventSigner = ref.watch(currentUserIonConnectEventSignerProvider).value;
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (eventSigner == null) {
    throw EventSignerNotFoundException();
  }

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final sealService = ref.watch(ionConnectSealServiceProvider).value;
  final wrapService = ref.watch(ionConnectGiftWrapServiceProvider).value;
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final devicePubkeysProvider = ref.watch(conversationPubkeysProvider.notifier);

  Future<void> sendWrappedEvent({
    required String pubkey,
    required String masterPubkey,
    required EventMessage eventMessage,
  }) async {
    if (sealService == null || wrapService == null) return;

    final seal = await sealService.createSeal(eventMessage, eventSigner, pubkey);

    final randomCreatedAt = randomDateBefore(const Duration(days: 2));

    final giftWrap = await wrapService.createWrap(
      event: seal,
      receiverPubkey: pubkey,
      randomCreatedAt: randomCreatedAt,
      receiverMasterPubkey: masterPubkey,
      contentKinds: [BlockedUserEntity.kind.toString()],
    );

    await ionConnectNotifier.sendEvent(
      giftWrap,
      cache: false,
      actionSource: ActionSourceUser(masterPubkey, anonymous: true),
    );
  }

  return BlockSyncStrategy(
    sendBlockEvent: (blockedUserMasterPubkey) async {
      final participantsMasterPubkeys = [currentUserMasterPubkey, blockedUserMasterPubkey];

      final participantsPubkeysMap =
          await devicePubkeysProvider.fetchUsersKeys(participantsMasterPubkeys);
      final createdAt = DateTime.now();

      await Future.wait(
        participantsMasterPubkeys.map((receiverMasterPubkey) async {
          final pubkeyDevices = participantsPubkeysMap[receiverMasterPubkey];

          if (pubkeyDevices == null) throw UserPubkeyNotFoundException(receiverMasterPubkey);

          for (final receiverPubkey in pubkeyDevices) {
            final eventMessage = await EventMessage.fromData(
              content: '',
              signer: eventSigner,
              kind: BlockedUserEntity.kind,
              createdAt: createdAt.microsecondsSinceEpoch,
              tags: [
                PubkeyTag(value: blockedUserMasterPubkey).toTag(),
                MasterPubkeyTag(value: currentUserMasterPubkey).toTag(),
              ],
            );

            await sendWrappedEvent(
              pubkey: receiverPubkey,
              eventMessage: eventMessage,
              masterPubkey: receiverMasterPubkey,
            );
          }
        }),
      );
    },
    deleteBlockEvent: (blockedUserMasterPubkey) async {
      final blockEventDao = ref.read(blockEventDaoProvider);
      final blockEventReferences = await blockEventDao.getBlockEventReferences(
        currentUserMasterPubkey: currentUserMasterPubkey,
        blockedUserMasterPubkey: blockedUserMasterPubkey,
      );

      if (blockEventReferences.isEmpty) return;

      final participantsMasterPubkeys = [currentUserMasterPubkey, blockedUserMasterPubkey];
      final participantsPubkeysMap =
          await devicePubkeysProvider.fetchUsersKeys(participantsMasterPubkeys);

      final eventsToDelete = blockEventReferences
          .whereType<ImmutableEventReference>()
          .map(
            (e) => EventToDelete(
              eventReference: e.copyWith(kind: BlockedUserEntity.kind),
            ),
          )
          .toList();

      if (eventsToDelete.isEmpty) return;

      final deleteRequest = DeletionRequest(events: eventsToDelete);

      final eventMessage = await deleteRequest.toEventMessage(
        NoPrivateSigner(eventSigner.publicKey),
        masterPubkey: currentUserMasterPubkey,
      );

      await Future.wait(
        participantsMasterPubkeys.map((receiverMasterPubkey) async {
          final pubkeyDevices = participantsPubkeysMap[receiverMasterPubkey];
          if (pubkeyDevices == null) {
            throw UserPubkeyNotFoundException(receiverMasterPubkey);
          } else if (pubkeyDevices.isEmpty) {
            return;
          }

          await Future.wait(
            pubkeyDevices.map((receiverPubkey) async {
              await sendWrappedEvent(
                pubkey: receiverPubkey,
                eventMessage: eventMessage,
                masterPubkey: receiverMasterPubkey,
              );
            }),
          );
        }),
      );
    },
  );
}
