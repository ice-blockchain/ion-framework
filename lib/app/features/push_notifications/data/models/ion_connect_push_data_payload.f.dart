// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/services/compressors/brotli_compressor.r.dart';
import 'package:ion/app/services/file_cache/ion_cache_manager.dart';
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:ion/app/utils/file_type_mapper.dart';

part 'ion_connect_push_data_payload.f.freezed.dart';
part 'ion_connect_push_data_payload.f.g.dart';

class IonConnectPushDataPayload {
  const IonConnectPushDataPayload._({
    required this.event,
    required this.relevantEvents,
    this.decryptedEvent,
    this.decryptedUserMetadata,
  });

  final EventMessage event;
  final List<EventMessage> relevantEvents;
  final EventMessage? decryptedEvent;
  final UserMetadataEntity? decryptedUserMetadata;

  static Future<IonConnectPushDataPayload> fromEncoded(
    Map<String, dynamic> data, {
    required Future<(EventMessage?, UserMetadataEntity?)> Function(EventMessage eventMassage)
        unwrapGift,
  }) async {
    final EncodedIonConnectPushData(:event, :relevantEvents, :compression) =
        EncodedIonConnectPushData.fromJson(data);

    final rawEvent = _decompress(input: event, compression: compression);
    final parsedEvent = EventMessage.fromPayloadJson(jsonDecode(rawEvent) as Map<String, dynamic>);

    final rawRelevantEvents = relevantEvents != null
        ? _decompress(input: relevantEvents, compression: compression)
        : null;
    final parsedRelevantEvents = rawRelevantEvents != null
        ? ((jsonDecode(rawRelevantEvents) as List<dynamic>)
            .map(
              (eventJson) => EventMessage.fromPayloadJson(eventJson as Map<String, dynamic>),
            )
            .toList())
        : <EventMessage>[];

    EventMessage? decryptedEvent;
    UserMetadataEntity? userMetadata;

    if (parsedEvent.kind == IonConnectGiftWrapEntity.kind) {
      final result = await unwrapGift(parsedEvent);
      decryptedEvent = result.$1;
      userMetadata = result.$2;
    }

    return IonConnectPushDataPayload._(
      event: parsedEvent,
      relevantEvents: parsedRelevantEvents,
      decryptedEvent: decryptedEvent,
      decryptedUserMetadata: userMetadata,
    );
  }

  IonConnectEntity get mainEntity {
    return EventParser().parse(event);
  }

  PushNotificationType? getNotificationType({
    required String currentPubkey,
  }) {
    final entity = mainEntity;
    if (entity is GenericRepostEntity ||
        entity is RepostEntity ||
        (entity is ModifiablePostEntity && entity.data.quotedEvent != null) ||
        (entity is PostEntity && entity.data.quotedEvent != null)) {
      return PushNotificationType.repost;
    } else if (entity is ModifiablePostEntity || entity is PostEntity) {
      final currentUserMention =
          ReplaceableEventReference(masterPubkey: currentPubkey, kind: UserMetadataEntity.kind)
              .encode();
      final content = switch (entity) {
        ModifiablePostEntity() => entity.data.content,
        PostEntity() => entity.data.content,
        _ => null
      };
      if (content?.contains(currentUserMention) ?? false) {
        return PushNotificationType.mention;
      } else {
        return PushNotificationType.reply;
      }
    } else if (entity is ReactionEntity) {
      return PushNotificationType.like;
    } else if (entity is FollowListEntity) {
      return PushNotificationType.follower;
    } else if (entity is IonConnectGiftWrapEntity) {
      if (entity.data.kinds.any((list) => list.contains(ReactionEntity.kind.toString()))) {
        return PushNotificationType.chatReaction;
      } else if (entity.data.kinds
          .any((list) => list.contains(FundsRequestEntity.kind.toString()))) {
        return PushNotificationType.paymentRequest;
      } else if (entity.data.kinds
          .any((list) => list.contains(WalletAssetEntity.kind.toString()))) {
        return PushNotificationType.paymentReceived;
      } else if (entity.data.kinds
          .any((list) => list.contains(ReplaceablePrivateDirectMessageEntity.kind.toString()))) {
        if (decryptedEvent == null) return null;

        final message = ReplaceablePrivateDirectMessageEntity.fromEventMessage(decryptedEvent!);
        switch (message.data.messageType) {
          case MessageType.audio:
            return PushNotificationType.chatVoiceMessage;
          case MessageType.document:
            return PushNotificationType.chatDocumentMessage;
          case MessageType.text:
            return PushNotificationType.chatTextMessage;
          case MessageType.emoji:
            return PushNotificationType.chatEmojiMessage;
          case MessageType.profile:
            return PushNotificationType.chatProfileMessage;
          case MessageType.sharedPost:
            return PushNotificationType.chatSharePostMessage;
          case MessageType.requestFunds:
            return PushNotificationType.chatPaymentRequestMessage;
          case MessageType.moneySent:
            return PushNotificationType.chatPaymentReceivedMessage;
          case MessageType.visualMedia:
            return _getVisualMediaNotificationType(message);
        }
      }
    }

    return null;
  }

  PushNotificationType _getVisualMediaNotificationType(
    ReplaceablePrivateDirectMessageEntity message,
  ) {
    final mediaItems = message.data.media.values.toList();

    if (mediaItems
        .every((media) => (media.mediaTypeEncrypted ?? media.mediaType) == MediaType.image)) {
      if (mediaItems.length == 1) {
        final mimeType = mediaItems.first.originalMimeType ?? mediaItems.first.mimeType;
        final isGif = mimeType.contains('gif');
        return isGif ? PushNotificationType.chatGifMessage : PushNotificationType.chatPhotoMessage;
      } else {
        final isGif =
            mediaItems.every((media) => (media.originalMimeType ?? media.mimeType).contains('gif'));
        return isGif
            ? PushNotificationType.chatMultiGifMessage
            : PushNotificationType.chatMultiPhotoMessage;
      }
    } else if (mediaItems
        .any((media) => (media.mediaTypeEncrypted ?? media.mediaType) == MediaType.video)) {
      final videoItems = mediaItems
          .where((media) => (media.mediaTypeEncrypted ?? media.mediaType) == MediaType.video)
          .toList();
      final thumbItems = mediaItems
          .where((media) => (media.mediaTypeEncrypted ?? media.mediaType) == MediaType.image)
          .toList();

      if (videoItems.length == 1 && thumbItems.length == 1) {
        return PushNotificationType.chatVideoMessage;
      } else if (videoItems.length == thumbItems.length) {
        return PushNotificationType.chatMultiVideoMessage;
      } else {
        return PushNotificationType.chatMultiMediaMessage;
      }
    }

    return PushNotificationType.chatMultiMediaMessage;
  }

  Future<Map<String, String>> placeholders(
    PushNotificationType notificationType, {
    required Future<MoneyDisplayData?> Function(EventMessage) getFundsRequestData,
    required Future<MoneyDisplayData?> Function(EventMessage) getTransactionData,
  }) async {
    final mainEntityUserMetadata = _getUserMetadata(pubkey: mainEntity.masterPubkey);

    final data = <String, String>{};

    if (mainEntityUserMetadata != null) {
      data.addAll({
        'username': mainEntityUserMetadata.data.name,
        'displayName': mainEntityUserMetadata.data.displayName,
      });
    } else if (decryptedUserMetadata != null) {
      data.addAll({
        'username': decryptedUserMetadata!.data.name,
        'displayName': decryptedUserMetadata!.data.displayName,
      });
    }

    if (decryptedEvent != null) {
      data['messageContent'] = decryptedEvent!.content;
      data['reactionContent'] = decryptedEvent!.content;
      final entity = mainEntity;

      if (entity is IonConnectGiftWrapEntity) {
        if (entity.data.kinds
            .any((list) => list.contains(ReplaceablePrivateDirectMessageEntity.kind.toString()))) {
          final message = ReplaceablePrivateDirectMessageEntity.fromEventMessage(decryptedEvent!);

          if (message.data.messageType == MessageType.requestFunds) {
            final fundsRequestData = await getFundsRequestData(decryptedEvent!);
            if (fundsRequestData != null) {
              data['coinAmount'] = fundsRequestData.amount;
              data['coinSymbol'] = fundsRequestData.coin;
            }
          }

          if (message.data.messageType == MessageType.moneySent) {
            final transactionData = await getTransactionData(decryptedEvent!);
            if (transactionData != null) {
              data['coinAmount'] = transactionData.amount;
              data['coinSymbol'] = transactionData.coin;
            }
          }

          if (notificationType == PushNotificationType.chatMultiGifMessage ||
              notificationType == PushNotificationType.chatMultiPhotoMessage) {
            data['fileCount'] = message.data.media.values.length.toString();
          }

          if (notificationType == PushNotificationType.chatMultiVideoMessage) {
            data['fileCount'] = message.data.media.values
                .where((media) => media.mediaType == MediaType.video)
                .length
                .toString();
          }

          if (notificationType == PushNotificationType.chatDocumentMessage) {
            final mimeType = message.data.primaryMedia?.originalMimeType;
            final fileType = FileTypeMapper.getFileType(mimeType);
            data['documentExt'] = fileType;
          }
        }
      }
    }

    return data;
  }

  Future<(String? avatar, String? attachment)> getMediaPlaceholders() async {
    final mainEntityUserMetadata = _getUserMetadata(pubkey: mainEntity.masterPubkey);
    final avatarUrl = mainEntityUserMetadata?.data.picture ?? decryptedUserMetadata?.data.picture;

    String? attachmentUrl;

    final entity = mainEntity;
    if (entity is IonConnectGiftWrapEntity &&
        entity.data.kinds
            .any((list) => list.contains(ReplaceablePrivateDirectMessageEntity.kind.toString())) &&
        decryptedEvent != null) {
      final message = ReplaceablePrivateDirectMessageEntity.fromEventMessage(decryptedEvent!);
      if (message.data.messageType == MessageType.visualMedia &&
          message.data.visualMedias.isNotEmpty) {
        // Decrypt media
        final mediaEncryptionService = MediaEncryptionService(
          fileCacheService: FileCacheService(IONCacheManager.instance),
          brotliCompressor: BrotliCompressor(),
          generateMediaUrlFallback: (url, {required String authorPubkey}) async {
            return null;
          },
        );

        final imageMedia = message.data.visualMedias.firstWhereOrNull(
          (media) =>
              (media.mediaType == MediaType.unknown ? media.mediaTypeEncrypted : media.mediaType) ==
              MediaType.image,
        );

        if (imageMedia != null) {
          final thumbMedia = message.data.media.values.firstWhereOrNull(
            (media) => media.url == imageMedia.thumb,
          );
          final decryptedMedia = await mediaEncryptionService.retrieveEncryptedMedia(
            thumbMedia ?? imageMedia,
            authorPubkey: message.pubkey,
          );
          attachmentUrl = decryptedMedia.path;
        }
      }
    }

    return (avatarUrl, attachmentUrl);
  }

  Future<bool> validate({required String currentPubkey}) async {
    final signaturesValid = await _checkEventsSignatures();
    final isMainEventRelevant = _checkMainEventRelevant(currentPubkey: currentPubkey);
    final requiredEventsPresent = _checkRequiredRelevantEvents();

    return signaturesValid && isMainEventRelevant && requiredEventsPresent;
  }

  static String _decompress({required String input, required Compression compression}) {
    return switch (compression) {
      Compression.zlib => utf8.decode(zlib.decode(base64.decode(input))),
      Compression.none => input,
    };
  }

  Future<bool> _checkEventsSignatures() async {
    final valid = await Future.wait(
      [
        event.validate(),
        ...relevantEvents.map((event) => event.validate()),
      ],
    );
    return valid.every((valid) => valid);
  }

  bool _checkMainEventRelevant({required String currentPubkey}) {
    final entity = mainEntity;
    if (entity is ModifiablePostEntity || entity is PostEntity) {
      final relatedPubkeys = switch (entity) {
        ModifiablePostEntity() => entity.data.relatedPubkeys,
        PostEntity() => entity.data.relatedPubkeys,
        _ => null
      };
      return relatedPubkeys != null &&
          relatedPubkeys.any((relatedPubkey) => relatedPubkey.value == currentPubkey);
    } else if (entity is GenericRepostEntity) {
      return entity.data.eventReference.masterPubkey == currentPubkey;
    } else if (entity is RepostEntity) {
      return entity.data.eventReference.masterPubkey == currentPubkey;
    } else if (entity is ReactionEntity) {
      return entity.data.eventReference.masterPubkey == currentPubkey;
    } else if (entity is FollowListEntity) {
      return entity.masterPubkeys.lastOrNull == currentPubkey;
    } else if (entity is IonConnectGiftWrapEntity) {
      return entity.data.relatedPubkeys
          .any((relatedPubkey) => relatedPubkey.value == currentPubkey);
    }
    return false;
  }

  bool _checkRequiredRelevantEvents() {
    if (event.kind == IonConnectGiftWrapEntity.kind) {
      return true;
    } else {
      // For all events except 1059 we need to check if delegation is present
      // in the relevant events and the main event valid for it
      final delegationEvent =
          relevantEvents.firstWhereOrNull((event) => event.kind == UserDelegationEntity.kind);
      if (delegationEvent == null) {
        return false;
      }
      final delegationEntity = EventParser().parse(delegationEvent) as UserDelegationEntity;
      return delegationEntity.data.validate(event);
    }
  }

  UserMetadataEntity? _getUserMetadata({required String pubkey}) {
    final delegationEvent = relevantEvents.firstWhereOrNull((event) {
      return event.kind == UserDelegationEntity.kind && event.pubkey == pubkey;
    });
    if (delegationEvent == null) {
      return null;
    }
    final eventParser = EventParser();
    final delegationEntity = eventParser.parse(delegationEvent) as UserDelegationEntity;

    for (final event in relevantEvents) {
      if (event.kind == UserMetadataEntity.kind && delegationEntity.data.validate(event)) {
        final userMetadataEntity = eventParser.parse(event) as UserMetadataEntity;
        if (userMetadataEntity.masterPubkey == delegationEntity.pubkey) {
          return userMetadataEntity;
        }
      }
    }
    return null;
  }
}

@Freezed(toJson: false)
class EncodedIonConnectPushData with _$EncodedIonConnectPushData {
  const factory EncodedIonConnectPushData({
    required String event,
    @JsonKey(name: 'relevant_events') String? relevantEvents,
    @Default(Compression.none) Compression compression,
  }) = _EncodedIonConnectPushData;

  factory EncodedIonConnectPushData.fromJson(Map<String, dynamic> json) =>
      _$EncodedIonConnectPushDataFromJson(json);
}

enum Compression {
  none,
  zlib,
}

enum PushNotificationType {
  reply,
  mention,
  repost,
  like,
  follower,
  paymentRequest,
  paymentReceived,
  chatDocumentMessage,
  chatEmojiMessage,
  chatPhotoMessage,
  chatProfileMessage,
  chatReaction,
  chatSharePostMessage,
  chatShareStoryMessage,
  chatSharedStoryReplyMessage,
  chatTextMessage,
  chatVideoMessage,
  chatVoiceMessage,
  chatFirstContactMessage,
  chatGifMessage,
  chatMultiGifMessage,
  chatMultiMediaMessage,
  chatMultiPhotoMessage,
  chatMultiVideoMessage,
  chatPaymentRequestMessage,
  chatPaymentReceivedMessage;

  bool get isChat => const {
        chatDocumentMessage,
        chatEmojiMessage,
        chatPhotoMessage,
        chatProfileMessage,
        chatReaction,
        chatSharePostMessage,
        chatShareStoryMessage,
        chatSharedStoryReplyMessage,
        chatTextMessage,
        chatVideoMessage,
        chatVoiceMessage,
        chatFirstContactMessage,
        chatGifMessage,
        chatMultiGifMessage,
        chatMultiMediaMessage,
        chatMultiPhotoMessage,
        chatMultiVideoMessage,
        chatPaymentRequestMessage,
        chatPaymentReceivedMessage,
      }.contains(this);
}
