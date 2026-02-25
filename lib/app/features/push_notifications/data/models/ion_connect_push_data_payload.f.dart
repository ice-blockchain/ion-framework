// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/message_type.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
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

  /// Check if this notification is about a self-interaction (user interacting with their own content)
  bool isSelfInteraction({required String currentPubkey}) {
    final entity = mainEntity;

    if (entity.masterPubkey == currentPubkey) {
      if (entity is ReactionEntity ||
          entity is GenericRepostEntity ||
          entity is RepostEntity ||
          (entity is ModifiablePostEntity &&
              (entity.data.quotedEvent != null || entity.data.parentEvent != null)) ||
          (entity is PostEntity &&
              (entity.data.quotedEvent != null || entity.data.parentEvent != null))) {
        return true;
      }
    }

    return false;
  }

  Future<PushNotificationType?> getNotificationType({
    required String currentPubkey,
    required Future<IonConnectEntity?> Function(EventReference) getRelatedEntity,
  }) async {
    final entity = mainEntity;

    if (entity is GenericRepostEntity || entity is RepostEntity) {
      return _getRepostNotificationType(entity, getRelatedEntity);
    } else if ((entity is ModifiablePostEntity && entity.data.quotedEvent != null) ||
        (entity is PostEntity && entity.data.quotedEvent != null)) {
      return _getQuoteNotificationType(entity, getRelatedEntity);
    } else if (entity is ReactionEntity) {
      return _getLikeNotificationType(entity, getRelatedEntity);
    } else if (entity is IonConnectGiftWrapEntity) {
      return _getGiftWrapNotificationType(entity);
    } else if (entity is FollowListEntity) {
      return PushNotificationType.follower;
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
      }
      return _getReplyNotificationType(entity, currentPubkey, getRelatedEntity);
    } else if (entity is WalletAssetEntity) {
      return PushNotificationType.paymentReceived;
    }

    return null;
  }

  Future<PushNotificationType> _getRepostNotificationType(
    IonConnectEntity entity,
    Future<IonConnectEntity?> Function(EventReference) getRelatedEntity,
  ) async {
    final repostedEntity = await getRelatedEntity(
      entity is GenericRepostEntity
          ? entity.data.eventReference
          : (entity as RepostEntity).data.eventReference,
    );

    if (repostedEntity is ArticleEntity) {
      return PushNotificationType.repostArticle;
    } else if (repostedEntity is ModifiablePostEntity && repostedEntity.data.parentEvent != null) {
      return PushNotificationType.repostComment;
    } else if (repostedEntity is PostEntity && repostedEntity.data.parentEvent != null) {
      return PushNotificationType.repostComment;
    }

    return PushNotificationType.repost;
  }

  Future<PushNotificationType> _getQuoteNotificationType(
    IonConnectEntity entity,
    Future<IonConnectEntity?> Function(EventReference) getRelatedEntity,
  ) async {
    final quotedEventRef = switch (entity) {
      ModifiablePostEntity() => entity.data.quotedEvent?.eventReference,
      PostEntity() => entity.data.quotedEvent?.eventReference,
      _ => null
    };

    if (quotedEventRef != null) {
      final quotedEntity = await getRelatedEntity(quotedEventRef);
      if (quotedEntity is ArticleEntity) {
        return PushNotificationType.quoteArticle;
      } else if (quotedEntity is ModifiablePostEntity && quotedEntity.data.parentEvent != null) {
        return PushNotificationType.quoteComment;
      } else if (quotedEntity is PostEntity && quotedEntity.data.parentEvent != null) {
        return PushNotificationType.quoteComment;
      }
    }

    return PushNotificationType.quote;
  }

  Future<PushNotificationType> _getReplyNotificationType(
    IonConnectEntity entity,
    String currentPubkey,
    Future<IonConnectEntity?> Function(EventReference) getRelatedEntity,
  ) async {
    final parentEventRef = switch (entity) {
      ModifiablePostEntity() => entity.data.parentEvent?.eventReference,
      PostEntity() => entity.data.parentEvent?.eventReference,
      _ => null
    };

    if (parentEventRef != null) {
      final parentEntity = await getRelatedEntity(parentEventRef);
      if (parentEntity is ArticleEntity) {
        return PushNotificationType.replyArticle;
      } else if (parentEntity is ModifiablePostEntity && parentEntity.data.parentEvent != null) {
        return PushNotificationType.replyComment;
      } else if (parentEntity is PostEntity && parentEntity.data.parentEvent != null) {
        return PushNotificationType.replyComment;
      }
      return PushNotificationType.reply;
    }

    return PushNotificationType.reply;
  }

  Future<PushNotificationType?> _getGiftWrapNotificationType(
    IonConnectGiftWrapEntity entity,
  ) async {
    if (entity.data.kinds.any((list) => list.contains(ReactionEntity.kind.toString()))) {
      return PushNotificationType.chatReaction;
    } else if (entity.data.kinds.any((list) => list.contains(FundsRequestEntity.kind.toString()))) {
      return PushNotificationType.paymentRequest;
    } else if (entity.data.kinds.any((list) => list.contains(WalletAssetEntity.kind.toString()))) {
      return PushNotificationType.paymentReceived;
    } else if (entity.data.kinds
        .any((list) => list.contains(ReplaceablePrivateDirectMessageEntity.kind.toString()))) {
      if (decryptedEvent == null) return null;
      if (decryptedUserMetadata == null) return PushNotificationType.chatFirstContactMessage;

      final message = ReplaceablePrivateDirectMessageEntity.fromEventMessage(decryptedEvent!);
      return _getChatMessageNotificationType(message);
    }

    return null;
  }

  Future<PushNotificationType> _getChatMessageNotificationType(
    ReplaceablePrivateDirectMessageEntity message,
  ) async {
    return switch (message.data.messageType) {
      MessageType.audio => PushNotificationType.chatVoiceMessage,
      MessageType.document => PushNotificationType.chatDocumentMessage,
      MessageType.text => PushNotificationType.chatTextMessage,
      MessageType.emoji => PushNotificationType.chatEmojiMessage,
      MessageType.profile => PushNotificationType.chatProfileMessage,
      MessageType.requestFunds => PushNotificationType.chatPaymentRequestMessage,
      MessageType.moneySent => PushNotificationType.chatPaymentReceivedMessage,
      MessageType.sharedPost => await _getSharedPostNotificationType(message),
      MessageType.visualMedia => _getVisualMediaNotificationType(message),
    };
  }

  Future<PushNotificationType> _getLikeNotificationType(
    ReactionEntity entity,
    Future<IonConnectEntity?> Function(EventReference) getRelatedEntity,
  ) async {
    final relatedEntity = await getRelatedEntity(entity.data.eventReference);

    return switch (relatedEntity) {
      ModifiablePostEntity(:final data) when data.expiration != null =>
        PushNotificationType.likeStory,
      ModifiablePostEntity(:final data) when data.parentEvent != null =>
        PushNotificationType.likeComment,
      ArticleEntity() => PushNotificationType.likeArticle,
      ModifiablePostEntity() => PushNotificationType.like,
      _ => PushNotificationType.like,
    };
  }

  Future<PushNotificationType> _getSharedPostNotificationType(
    ReplaceablePrivateDirectMessageEntity message,
  ) async {
    // If message has content, it's a reply to a shared story
    if (message.data.content.isNotEmpty) {
      return PushNotificationType.chatSharedStoryReplyMessage;
    }
    final quotedEventKind = message.data.quotedEventKind;
    if (quotedEventKind != null) {
      switch (int.parse(quotedEventKind)) {
        case ModifiablePostEntity.kind || PostEntity.kind:
          return PushNotificationType.chatSharePostMessage;
        case ModifiablePostEntity.storyKind:
          return PushNotificationType.chatShareStoryMessage;
        case ArticleEntity.kind:
          return PushNotificationType.chatShareArticleMessage;
        default:
          return PushNotificationType.chatSharePostMessage;
      }
    }

    return PushNotificationType.chatSharePostMessage;
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
            final media = message.data.media.values.where((media) => media.thumb == null).toList();
            data['fileCount'] = media.length.toString();
          }

          if (notificationType == PushNotificationType.chatMultiVideoMessage) {
            data['fileCount'] = message.data.media.values
                .where((media) => media.mediaType == MediaType.video && media.thumb == null)
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
          generateMediaUrlFallback: (url, {required String authorPubkey}) async => true,
          getMediaUrl: (String url) => url,
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
          final decryptedMedia = await mediaEncryptionService.getEncryptedMedia(
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

      final event = switch (entity) {
        ModifiablePostEntity() => entity.data.quotedEvent,
        PostEntity() => entity.data.quotedEvent,
        _ => null
      };

      final isInRelatedPubkeys = relatedPubkeys != null &&
          relatedPubkeys.any((relatedPubkey) => relatedPubkey.value == currentPubkey);

      final isPostAuthor = event != null && event.eventReference.masterPubkey == currentPubkey;

      return isInRelatedPubkeys || isPostAuthor;
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
  replyArticle,
  replyComment,
  mention,
  repost,
  repostArticle,
  repostComment,
  quote,
  quoteArticle,
  quoteComment,
  like,
  likeArticle,
  likeComment,
  likeStory,
  follower,
  paymentRequest,
  paymentReceived,
  chatDocumentMessage,
  chatEmojiMessage,
  chatPhotoMessage,
  chatProfileMessage,
  chatReaction,
  chatSharePostMessage,
  chatShareArticleMessage,
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
        chatShareArticleMessage,
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
