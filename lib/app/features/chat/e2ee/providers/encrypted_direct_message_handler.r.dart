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
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_direct_message_handler.r.g.dart';

class EncryptedDirectMessageHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedDirectMessageHandler({
    required this.masterPubkey,
    required this.conversationDao,
    required this.messageMediaDao,
    required this.conversationMessageDao,
    required this.mediaEncryptionService,
    required this.conversationMessageDataDao,
    required this.conversationEventMessageDao,
    required this.sendE2eeMessageStatusService,
    required this.fileCacheService,
  });

  final String masterPubkey;
  final ConversationDao conversationDao;
  final MessageMediaDao messageMediaDao;
  final MediaEncryptionService mediaEncryptionService;
  final ConversationMessageDao conversationMessageDao;
  final ConversationMessageDataDao conversationMessageDataDao;
  final ConversationEventMessageDao conversationEventMessageDao;
  final SendE2eeMessageStatusService sendE2eeMessageStatusService;
  final FileCacheService fileCacheService;

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
    final eventReference = entity.toEventReference();
    // Check if the conversation was deleted earlier (needed only for recovery)
    if (await conversationDao.conversationIsNotDeleted(
          entity.data.conversationId,
          entity.createdAt,
        ) &&
        await conversationMessageDao.messageIsNotDeleted(eventReference)) {
      await _addDirectMessageToDatabase(rumor);
    }

    return entity.toEventReference();
  }

  Future<void> _addDirectMessageToDatabase(EventMessage rumor) async {
    await conversationDao.add([rumor]);
    await conversationEventMessageDao.add(rumor);
    unawaited(_addMediaToDatabase(rumor));
  }

  Future<void> _clearOldMedia({
    required EventReference eventReference,
  }) async {
    // Remove old media records and cached files for this message
    final existingMediaRecords = await (messageMediaDao.select(messageMediaDao.messageMediaTable)
          ..where((t) => t.messageEventReference.equalsValue(eventReference)))
        .get();

    for (final mediaRecord in existingMediaRecords) {
      if (mediaRecord.remoteUrl?.isNotEmpty ?? false) {
        unawaited(fileCacheService.removeFile(mediaRecord.remoteUrl!));
      }
    }

    await (messageMediaDao.delete(messageMediaDao.messageMediaTable)
          ..where((t) => t.messageEventReference.equalsValue(eventReference)))
        .go();
  }

  Future<void> _addMediaToDatabase(EventMessage rumor) async {
    final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(rumor);
    if (entity.data.media.isNotEmpty) {
      final eventReference = entity.toEventReference();

      await _clearOldMedia(eventReference: eventReference);

      for (final media in entity.data.media.values) {
        unawaited(
          mediaEncryptionService
              .getEncryptedMedia(
            media,
            authorPubkey: rumor.masterPubkey,
          )
              .then((_) async {
            final isThumb =
                entity.data.media.values.any((m) => m.url != media.url && m.thumb == media.url);

            if (isThumb) {
              return;
            }

            await messageMediaDao.add(
              remoteUrl: media.url,
              status: MessageMediaStatus.completed,
              eventReference: eventReference,
            );
          }),
        );
      }
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
    masterPubkey: masterPubkey,
    messageMediaDao: ref.watch(messageMediaDaoProvider),
    conversationDao: ref.watch(conversationDaoProvider),
    conversationMessageDao: ref.watch(conversationMessageDaoProvider),
    mediaEncryptionService: ref.watch(mediaEncryptionServiceProvider),
    conversationEventMessageDao: ref.watch(conversationEventMessageDaoProvider),
    conversationMessageDataDao: ref.watch(conversationMessageDataDaoProvider),
    sendE2eeMessageStatusService: await ref.watch(sendE2eeMessageStatusServiceProvider.future),
    fileCacheService: ref.watch(ionConnectFileCacheServiceProvider),
  );
}
