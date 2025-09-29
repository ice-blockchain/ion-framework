// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_e2ee_message_status_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/user_profile/providers/user_profile_sync_provider.r.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_direct_message_handler.r.g.dart';

class EncryptedDirectMessageHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedDirectMessageHandler(
    this.masterPubkey,
    this.conversationDao,
    this.conversationEventMessageDao,
    this.conversationMessageDataDao,
    this.messageMediaDao,
    this.sendE2eeMessageStatusService,
    this.mediaEncryptionService,
    this.userProfileSyncProvider,
  );

  final String masterPubkey;
  final ConversationDao conversationDao;
  final ConversationEventMessageDao conversationEventMessageDao;
  final ConversationMessageDataDao conversationMessageDataDao;
  final MessageMediaDao messageMediaDao;
  final SendE2eeMessageStatusService sendE2eeMessageStatusService;
  final MediaEncryptionService mediaEncryptionService;
  final UserProfileSync userProfileSyncProvider;

  @override
  bool canHandle({
    required IonConnectGiftWrapEntity entity,
  }) {
    return entity.data.kinds.any(
      (kinds) => kinds.contains(ReplaceablePrivateDirectMessageEntity.kind.toString()),
    );
  }

  @override
  Future<EventReference> handle(EventMessage rumor) async {
    final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(rumor);
    await _addDirectMessageToDatabase(rumor);
    unawaited(_sendReceivedStatus(rumor));
    unawaited(userProfileSyncProvider.syncUserProfile(masterPubkeys: {rumor.masterPubkey}));

    return entity.toEventReference();
  }

  Future<void> _addDirectMessageToDatabase(
    EventMessage rumor,
  ) async {
    await conversationDao.add([rumor]);
    await conversationEventMessageDao.add(rumor);
    await _addMediaToDatabase(rumor);
  }

  Future<void> _addMediaToDatabase(
    EventMessage rumor,
  ) async {
    final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(rumor);
    if (entity.data.media.isNotEmpty) {
      for (final media in entity.data.media.values) {
        await mediaEncryptionService.retrieveEncryptedMedia(
          media,
          authorPubkey: rumor.masterPubkey,
        );
        final isThumb =
            entity.data.media.values.any((m) => m.url != media.url && m.thumb == media.url);

        if (isThumb) {
          continue;
        }
        await messageMediaDao.add(
          eventReference: entity.toEventReference(),
          status: MessageMediaStatus.completed,
          remoteUrl: media.url,
        );
      }
    }
  }

  Future<void> _sendReceivedStatus(
    EventMessage rumor,
  ) async {
    final eventReference =
        ReplaceablePrivateDirectMessageEntity.fromEventMessage(rumor).toEventReference();

    final currentStatus = await conversationMessageDataDao.checkMessageStatus(
      eventReference: eventReference,
      masterPubkey: masterPubkey,
    );

    if (currentStatus == null || currentStatus.index < MessageDeliveryStatus.received.index) {
      // Notify rest of the participants that the message was received
      // by the current user
      await sendE2eeMessageStatusService.sendMessageStatus(
        messageEventMessage: rumor,
        status: MessageDeliveryStatus.received,
      );
    }

    // If we recovered keypair, current user will not have "read" message status
    // as we don't send it
    if (rumor.masterPubkey == masterPubkey) {
      await conversationMessageDataDao.addOrUpdateStatus(
        pubkey: rumor.pubkey,
        masterPubkey: rumor.masterPubkey,
        status: MessageDeliveryStatus.read,
        messageEventReference: eventReference,
      );
    }
  }
}

@riverpod
Future<EncryptedDirectMessageHandler?> encryptedDirectMessageHandler(Ref ref) async {
  final masterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (masterPubkey == null) {
    return null;
  }

  return EncryptedDirectMessageHandler(
    masterPubkey,
    ref.watch(conversationDaoProvider),
    ref.watch(conversationEventMessageDaoProvider),
    ref.watch(conversationMessageDataDaoProvider),
    ref.watch(messageMediaDaoProvider),
    await ref.watch(sendE2eeMessageStatusServiceProvider.future),
    ref.watch(mediaEncryptionServiceProvider),
    ref.watch(userProfileSyncProvider.notifier),
  );
}
