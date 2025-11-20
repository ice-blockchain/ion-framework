// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_saver/file_saver.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_chat_media_provider.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/group_subject.f.dart';
import 'package:ion/app/features/chat/providers/conversation_pubkeys_provider.r.dart';
import 'package:ion/app/features/chat/services/shared_chat_isolate.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_editing_ended_at.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_expiration.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_gift_wrap_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_seal_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/uuid/uuid.dart';
import 'package:ion/app/utils/date.dart';
import 'package:nip44/nip44.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_e2ee_chat_message_service.r.g.dart';

@riverpod
SendE2eeChatMessageService sendE2eeChatMessageService(Ref ref) {
  return SendE2eeChatMessageService(ref);
}

class SendE2eeChatMessageService {
  SendE2eeChatMessageService(this.ref);

  final Ref ref;

  Future<EventMessage> sendMessage({
    required String content,
    required String conversationId,
    required List<String> participantsMasterPubkeys,
    int? kind,
    List<List<String>>? tags,
    String? subject,
    EventMessage? editedMessage,
    EventMessage? repliedMessage,
    EventMessage? failedEventMessage,
    List<String>? groupImageTag,
    QuotedImmutableEvent? quotedEvent,
    String? quotedEventKind,
    List<MediaFile> mediaFiles = const [],
    Map<String, List<String>>? failedParticipantsMasterPubkeys,
  }) async {
    final trimmedContent = content.trim();

    final preparedMediaFiles =
        mediaFiles.map((e) => e.copyWith(originalMimeType: e.mimeType)).toList();

    EventMessage? sentMessage;

    final sharedId = editedMessage?.sharedId ?? failedEventMessage?.sharedId ?? generateUuid();
    ReplaceableEventReference? eventReference;

    final editedMessageEntity = editedMessage != null
        ? ReplaceablePrivateDirectMessageData.fromEventMessage(editedMessage)
        : null;
    final participantsPubkeysMap = failedParticipantsMasterPubkeys ??
        await ref
            .read(conversationPubkeysProvider.notifier)
            .fetchUsersKeys(participantsMasterPubkeys);

    final createdAt = DateTime.now().microsecondsSinceEpoch;
    final randomCreatedAt = randomDateBefore();

    try {
      final publishedAt = editedMessageEntity?.publishedAt ?? EntityPublishedAt(value: createdAt);

      final editingEndedAt = editedMessageEntity?.editingEndedAt ??
          EntityEditingEndedAt.build(
            ref.read(envProvider.notifier).get<int>(EnvVariable.EDIT_MESSAGE_ALLOWED_MINUTES),
          );

      final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);

      if (eventSigner == null) {
        throw EventSignerNotFoundException();
      }

      final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

      if (currentUserMasterPubkey == null) {
        throw UserMasterPubkeyNotFoundException();
      }

      final paymentRequested =
          _getTagValue(ReplaceablePrivateDirectMessageData.paymentRequestedTagName, tags);
      final paymentSent =
          _getTagValue(ReplaceablePrivateDirectMessageData.paymentSentTagName, tags);

      final localEventMessageData = ReplaceablePrivateDirectMessageData(
        content: trimmedContent,
        paymentRequested: paymentRequested,
        paymentSent: paymentSent,
        messageId: sharedId,
        publishedAt: publishedAt,
        editingEndedAt: editingEndedAt,
        conversationId: conversationId,
        media: {
          for (final attachment in preparedMediaFiles.map(MediaAttachment.fromMediaFile))
            attachment.url: attachment,
        },
        masterPubkey: currentUserMasterPubkey,
        groupSubject: subject.isNotEmpty ? GroupSubject(subject!) : null,
        relatedPubkeys:
            participantsMasterPubkeys.map((pubkey) => RelatedPubkey(value: pubkey)).toList(),
        quotedEvent: quotedEvent ?? editedMessageEntity?.quotedEvent,
        quotedEventKind: quotedEventKind,
        relatedEvents: editedMessageEntity?.relatedEvents ?? _generateRelatedEvents(repliedMessage),
      );

      eventReference = localEventMessageData.toReplaceableEventReference(currentUserMasterPubkey);

      final localEventMessage = await localEventMessageData
          .toEventMessage(NoPrivateSigner(eventSigner.publicKey), createdAt: createdAt);

      sentMessage = localEventMessage;

      final messageMediaIds = await _addDbEntities(
        mediaFiles: preparedMediaFiles,
        eventReference: eventReference,
        localEventMessage: localEventMessage,
      );

      final mediaAttachmentsUsersBased = await _sendMediaFiles(
        randomCreatedAt: randomCreatedAt,
        mediaFiles: preparedMediaFiles,
        messageMediaIds: messageMediaIds,
        eventReference: eventReference,
        participantsMasterPubkeys: participantsPubkeysMap.keys.toList(),
      );

      participantsMasterPubkeys.sort((a, b) {
        if (a == currentUserMasterPubkey) return 1;
        if (b == currentUserMasterPubkey) return -1;
        return a.compareTo(b);
      });

      if (mediaAttachmentsUsersBased.isEmpty && trimmedContent.isEmpty && quotedEvent == null) {
        await ref.read(eventMessageDaoProvider).deleteByEventReference(eventReference);
        return sentMessage;
      }

      final receiverMasterPubkey =
          participantsMasterPubkeys.firstWhere((pubkey) => pubkey != currentUserMasterPubkey);

      final isBlockedByReceiver =
          await ref.read(isBlockedByNotifierProvider(receiverMasterPubkey).future);

      await Future.wait(
        participantsMasterPubkeys.map((masterPubkey) async {
          final pubkeyDevices = participantsPubkeysMap[masterPubkey];

          if (pubkeyDevices == null) throw UserPubkeyNotFoundException(masterPubkey);

          final attachments = mediaAttachmentsUsersBased[masterPubkey] ?? [];

          final isCurrentUser = currentUserMasterPubkey == masterPubkey;

          for (final pubkey in pubkeyDevices) {
            try {
              final remoteEventMessage = await ReplaceablePrivateDirectMessageData(
                content: trimmedContent,
                paymentRequested: paymentRequested,
                paymentSent: paymentSent,
                messageId: sharedId,
                publishedAt: publishedAt,
                editingEndedAt: editingEndedAt,
                conversationId: conversationId,
                groupSubject: subject.isNotEmpty ? GroupSubject(subject!) : null,
                media: {
                  for (final attachment in attachments) attachment.url: attachment,
                },
                masterPubkey: currentUserMasterPubkey,
                quotedEvent: quotedEvent ?? editedMessageEntity?.quotedEvent,
                quotedEventKind: quotedEventKind,
                relatedPubkeys: participantsMasterPubkeys
                    .map((pubkey) => RelatedPubkey(value: pubkey))
                    .toList(),
                relatedEvents:
                    editedMessageEntity?.relatedEvents ?? _generateRelatedEvents(repliedMessage),
              ).toEventMessage(NoPrivateSigner(eventSigner.publicKey), createdAt: createdAt);

              if (!isBlockedByReceiver) {
                final messageKind = ReplaceablePrivateDirectMessageEntity.kind.toString();

                await sendWrappedMessage(
                  pubkey: pubkey,
                  eventSigner: eventSigner,
                  masterPubkey: masterPubkey,
                  randomCreatedAt: randomCreatedAt,
                  wrappedKinds: kind != null ? [messageKind, kind.toString()] : [messageKind],
                  eventMessage: remoteEventMessage,
                );
              }

              if (eventReference != null) {
                await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                      pubkey: pubkey,
                      masterPubkey: masterPubkey,
                      messageEventReference: eventReference,
                      status:
                          isCurrentUser ? MessageDeliveryStatus.read : MessageDeliveryStatus.sent,
                    );
              }
            } catch (e) {
              Logger.log(e.toString());
              if (eventReference != null) {
                await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                      pubkey: pubkey,
                      messageEventReference: eventReference,
                      masterPubkey: masterPubkey,
                      status: MessageDeliveryStatus.failed,
                    );
              }
            }
          }
        }),
      );
    } catch (e) {
      if (eventReference != null) {
        for (final masterPubkey in participantsMasterPubkeys) {
          final pubkeyDevices = participantsPubkeysMap[masterPubkey];
          if (pubkeyDevices == null) continue;
          for (final pubkey in pubkeyDevices) {
            await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
                  pubkey: pubkey,
                  messageEventReference: eventReference,
                  masterPubkey: masterPubkey,
                  status: MessageDeliveryStatus.failed,
                );
          }
        }
      }
      throw SendEventException(e.toString());
    }

    return Future.value(sentMessage);
  }

  String? _getTagValue(String tagName, List<List<String>>? tags) {
    final tag = tags?.firstWhereOrNull(
      (t) => t.isNotEmpty && t.first == tagName,
    );
    return (tag != null && tag.length > 1) ? tag[1] : null;
  }

  List<RelatedReplaceableEvent> _generateRelatedEvents(EventMessage? repliedMessage) {
    if (repliedMessage != null) {
      final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(repliedMessage);

      final rootRelatedEvent = entity.data.rootRelatedEvent;

      return [
        if (rootRelatedEvent != null) rootRelatedEvent,
        RelatedReplaceableEvent(
          eventReference: entity.toEventReference(),
          pubkey: repliedMessage.masterPubkey,
          marker: RelatedEventMarker.reply,
        ),
      ];
    }

    return [];
  }

  Future<Map<String, List<MediaAttachment>>> _sendMediaFiles({
    required DateTime randomCreatedAt,
    required EventReference eventReference,
    required List<int> messageMediaIds,
    required List<MediaFile> mediaFiles,
    required List<String> participantsMasterPubkeys,
  }) async {
    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
    final mediaAttachmentsUsersBased = <String, List<MediaAttachment>>{};

    final mediaAttachmentsFutures = mediaFiles.map(
      (mediaFile) async {
        final indexOfMediaFile = mediaFiles.indexOf(mediaFile);
        final id = messageMediaIds[indexOfMediaFile];

        final sendResult = await ref
            .read(sendChatMediaProvider(id).notifier)
            .sendChatMedia(participantsMasterPubkeys, randomCreatedAt, mediaFile);

        final currentUserSendResult =
            sendResult.firstWhereOrNull((a) => a.$1 == currentUserMasterPubkey);
        if (currentUserSendResult == null) {
          return sendResult;
        }

        await ref.read(messageMediaDaoProvider).updateById(
              id,
              eventReference,
              currentUserSendResult.$2.first.url,
              MessageMediaStatus.completed,
            );

        return sendResult;
      },
    ).toList();

    final mediaAttachmentsLists = await Future.wait(mediaAttachmentsFutures);

    // Check which media records still exist (some may have been cancelled)
    final existingMediaRecords = await (ref.read(chatDatabaseProvider).select(
          ref.read(chatDatabaseProvider).messageMediaTable,
        )
              ..where((t) => t.messageEventReference.equalsValue(eventReference)))
        .get();

    // Get IDs of media that still exist (weren't cancelled)
    final existingMediaIds = existingMediaRecords.map((record) => record.id).toSet();

    // Only include media attachments for files that weren't cancelled
    for (var i = 0; i < mediaAttachmentsLists.length; i++) {
      final mediaId = messageMediaIds[i];

      // Skip this media if it was cancelled
      if (!existingMediaIds.contains(mediaId)) {
        continue;
      }

      final mediaAttachments = mediaAttachmentsLists[i];
      for (final (pubkey, attachment) in mediaAttachments) {
        mediaAttachmentsUsersBased.update(
          pubkey,
          (attachments) => [...attachments, ...attachment],
          ifAbsent: () => attachment,
        );
      }
    }

    return mediaAttachmentsUsersBased;
  }

  Future<void> sendWrappedMessage({
    required String pubkey,
    required String masterPubkey,
    required EventSigner eventSigner,
    required EventMessage eventMessage,
    required List<String> wrappedKinds,
    DateTime? randomCreatedAt,
  }) async {
    final env = ref.read(envProvider.notifier);
    final expirationDuration = Duration(
      hours: env.get<int>(EnvVariable.GIFT_WRAP_EXPIRATION_HOURS),
    );
    final giftWrapService = await ref.read(ionConnectGiftWrapServiceProvider.future);
    final sealService = await ref.read(ionConnectSealServiceProvider.future);

    final randomCreatedAtTime = randomCreatedAt ?? randomDateBefore();

    final expirationTag =
        EntityExpiration(value: randomCreatedAtTime.add(expirationDuration).microsecondsSinceEpoch)
            .toTag();

    final giftWrap = await sharedChatIsolate.compute(
      createGiftWrapFn,
      [
        sealService,
        giftWrapService,
        eventMessage,
        eventSigner,
        pubkey,
        masterPubkey,
        expirationTag,
        wrappedKinds,
        randomCreatedAtTime,
      ],
    );

    await ref.read(ionConnectNotifierProvider.notifier).sendEvent(
          giftWrap,
          cache: false,
          actionSource: ActionSource.user(masterPubkey, anonymous: true),
        );
  }

  Future<void> resendMessage({required EventMessage eventMessage}) async {
    final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage);
    final eventReference = entity.toEventReference();

    await ref
        .read(conversationMessageDataDaoProvider)
        .reinitializeFailedStatus(eventReference: eventReference);

    final failedParticipantsMasterPubkeys = await ref
        .read(conversationMessageDataDaoProvider)
        .getFailedParticipants(eventReference: eventReference);

    final mediaFiles = entity.data.media.values
        .map(
          (media) => MediaFile(
            path: media.url,
            mimeType: media.mimeType,
            originalMimeType: media.originalMimeType,
            height: media.dimension?.split('x').firstOrNull?.map(int.tryParse),
            width: media.dimension?.split('x').lastOrNull?.map(int.tryParse),
          ),
        )
        .toList();

    await sendMessage(
      mediaFiles: mediaFiles,
      content: eventMessage.content,
      failedEventMessage: eventMessage,
      quotedEvent: entity.data.quotedEvent,
      quotedEventKind: entity.data.quotedEventKind,
      conversationId: entity.data.conversationId,
      participantsMasterPubkeys: entity.allPubkeys,
      failedParticipantsMasterPubkeys:
          failedParticipantsMasterPubkeys.isNotEmpty ? failedParticipantsMasterPubkeys : null,
    );
  }

  Future<List<String>> _generateCacheKeys(List<MediaFile> mediaFiles) async {
    final cacheKeys = <String>[];

    for (final mediaFile in mediaFiles) {
      final file = File(mediaFile.path);
      final fileName = generateUuid();
      final isVideo = MediaType.fromMimeType(mediaFile.originalMimeType ?? '') == MediaType.video;

      if (isVideo) {
        final thumb = await ref.read(videoCompressorProvider).getThumbnail(mediaFile);
        await FileSaver.instance.saveFileOnly(name: fileName, file: File(thumb.path));
      } else {
        await FileSaver.instance.saveFileOnly(name: fileName, file: file);
      }
      cacheKeys.add(fileName);
    }

    return cacheKeys;
  }

  Future<List<int>> _addDbEntities({
    required List<MediaFile> mediaFiles,
    required EventReference eventReference,
    required EventMessage localEventMessage,
  }) async {
    final cacheKeys = await _generateCacheKeys(mediaFiles);

    var messageMediaIds = <int>[];
    await ref.read(chatDatabaseProvider).transaction(() async {
      await ref.read(conversationDaoProvider).add([localEventMessage]);
      await ref.read(conversationEventMessageDaoProvider).add(localEventMessage);
      await ref.read(conversationMessageDataDaoProvider).addOrUpdateStatus(
            messageEventReference: eventReference,
            pubkey: localEventMessage.pubkey,
            status: MessageDeliveryStatus.created,
            masterPubkey: localEventMessage.masterPubkey,
          );

      messageMediaIds = await ref.read(messageMediaDaoProvider).addBatch(
            cacheKeys: cacheKeys,
            eventReference: eventReference,
          );
    });

    return messageMediaIds;
  }
}

@pragma('vm:entry-point')
Future<EventMessage> createGiftWrapFn(List<dynamic> args) async {
  final sealService = args[0] as IonConnectSealService;
  final giftWrapService = args[1] as IonConnectGiftWrapService;
  final eventMessage = args[2] as EventMessage;
  final signer = args[3] as EventSigner;
  final receiverPubkey = args[4] as String;
  final receiverMasterPubkey = args[5] as String;
  final expirationTag = args[6] as List<String>;
  final kinds = args[7] as List<String>;
  final randomCreatedAt = args[8] as DateTime;

  final seal = await sealService.createSeal(
    eventMessage,
    signer,
    receiverPubkey,
    compressionAlgorithm: CompressionAlgorithm.brotli,
  );

  return giftWrapService.createWrap(
    event: seal,
    contentKinds: kinds,
    receiverPubkey: receiverPubkey,
    randomCreatedAt: randomCreatedAt,
    receiverMasterPubkey: receiverMasterPubkey,
    expirationTag: expirationTag,
    compressionAlgorithm: CompressionAlgorithm.brotli,
  );
}
