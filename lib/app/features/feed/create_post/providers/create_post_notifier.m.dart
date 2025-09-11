// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/utils/build_empty_delta.dart';
import 'package:ion/app/components/text_editor/utils/extract_tags.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests_interaction.dart';
import 'package:ion/app/features/feed/data/models/who_can_reply_settings_option.f.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/providers/counters/helpers/counter_cache_helpers.r.dart';
import 'package:ion/app/features/feed/providers/counters/replies_count_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/media_upload_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_parent.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_settings.dart';
import 'package:ion/app/features/ion_connect/model/entity_editing_ended_at.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_expiration.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata_builder.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/model/replaceable_event_identifier.f.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';
import 'package:ion/app/features/ion_connect/model/source_post_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_delete_file_notifier.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:ion/app/features/user/providers/verified_user_events_metadata_provider.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/markdown/quill.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_post_notifier.m.g.dart';

final _createPostNotifierStreamController = StreamController<IonConnectEntity>.broadcast();

@riverpod
Raw<Stream<IonConnectEntity>> createPostNotifierStream(Ref ref) {
  return _createPostNotifierStreamController.stream;
}

@riverpod
class CreatePostNotifier extends _$CreatePostNotifier {
  @override
  FutureOr<void> build(CreatePostOption createOption) {}

  Future<void> create({
    Delta? content,
    WhoCanReplySettingsOption whoCanReply = const WhoCanReplySettingsOption.everyone(),
    EventReference? parentEvent,
    EventReference? quotedEvent,
    EventReference? sourcePostReference,
    List<MediaFile>? mediaFiles,
    String? communityId,
    PollData? poll,
    Set<String> topics = const {},
    String? language,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final postContent = content ?? buildEmptyDelta();
      final parentEntity = parentEvent != null ? await _getEntity(parentEvent) : null;
      final quotedEntity = quotedEvent != null ? await _getEntity(quotedEvent) : null;
      final (:files, :media) = await _uploadMediaFiles(mediaFiles: mediaFiles);
      final mentions = _buildMentions(postContent);

      final parentQuotedTopics = _getTopicsFromParentAndQuoted(parentEntity, quotedEntity);
      if (topics.isEmpty && parentQuotedTopics.isEmpty) {
        topics.add(FeedInterests.unclassified);
      }
      final relatedHashtags = {
        ...topics.map((topic) => RelatedHashtag(value: topic)),
        ...parentQuotedTopics.map((topic) => RelatedHashtag(value: topic)),
        ...extractTags(postContent).map((tag) => RelatedHashtag(value: tag)),
      }.toList();

      final postData = ModifiablePostData(
        textContent: '',
        media: media,
        replaceableEventId: ReplaceableEventIdentifier.generate(),
        publishedAt: _buildEntityPublishedAt(),
        editingEndedAt: _buildEditingEndedAt(),
        relatedHashtags: relatedHashtags,
        quotedEvent: quotedEvent != null ? _buildQuotedEvent(quotedEvent) : null,
        relatedEvents: parentEntity != null ? _buildRelatedEvents(parentEntity) : null,
        sourcePostReference: sourcePostReference != null
            ? SourcePostReference(eventReference: sourcePostReference)
            : null,
        relatedPubkeys:
            _buildRelatedPubkeys(mentions: mentions, parentEntity: parentEntity).toList(),
        settings:
            parentEntity != null ? null : EntityDataWithSettings.build(whoCanReply: whoCanReply),
        expiration: _buildExpiration(),
        communityId: communityId,
        richText: await _buildRichTextContentWithMediaLinks(
          content: postContent,
          media: media.values.toList(),
        ),
        poll: poll,
        language: _buildLanguageLabel(language),
      );

      final post = await _publishPost(
        postData,
        files: files,
        mentions: mentions,
        quotedEvent: quotedEvent,
        parentEntity: parentEntity,
      );

      _createPostNotifierStreamController.add(post);

      if (quotedEvent != null) {
        await ref.read(quoteCounterUpdaterProvider).updateQuoteCounter(
              quotedEvent,
              isAdding: true,
            );
      }
      if (parentEvent != null) {
        ref.read(repliesCountProvider(parentEvent).notifier).addOne();
      }

      await _updateInterests(post);
    });
  }

  Future<void> modify({
    required EventReference eventReference,
    Delta? content,
    // New media files added during the editing
    List<MediaFile>? mediaFiles,
    // Media attachments left from the original post
    Map<String, MediaAttachment> mediaAttachments = const {},
    WhoCanReplySettingsOption? whoCanReply,
    Set<String> topics = const {},
    PollData? poll,
    String? language,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final postContent = content ?? buildEmptyDelta();
      final modifiedEntity =
          await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);

      if (modifiedEntity is! ModifiablePostEntity) {
        throw UnsupportedEventReference(eventReference);
      }

      final parentEvent = modifiedEntity.data.parentEvent?.eventReference;
      final quotedEvent = modifiedEntity.data.quotedEvent?.eventReference;
      final parentEntity = parentEvent != null ? await _getEntity(parentEvent) : null;
      final mentions = _buildMentions(postContent);

      final (:files, :media) = await _uploadMediaFiles(mediaFiles: mediaFiles);
      final modifiedMedia = Map<String, MediaAttachment>.from(mediaAttachments)..addAll(media);

      if (topics.contains(FeedInterests.unclassified) && topics.length > 1) {
        topics.remove(FeedInterests.unclassified);
      } else if (topics.isEmpty) {
        topics.add(FeedInterests.unclassified);
      }
      final relatedHashtags = [
        ...topics.map((topic) => RelatedHashtag(value: topic)),
        ...extractTags(postContent).map((tag) => RelatedHashtag(value: tag)),
      ];

      final postData = modifiedEntity.data.copyWith(
        textContent: '',
        richText: await _buildRichTextContentWithMediaLinks(
          content: postContent,
          media: modifiedMedia.values.toList(),
        ),
        media: modifiedMedia,
        relatedHashtags: relatedHashtags,
        relatedPubkeys:
            _buildRelatedPubkeys(mentions: _buildMentions(postContent), parentEntity: parentEntity)
                .toList(),
        settings: EntityDataWithSettings.build(
          whoCanReply: whoCanReply ?? modifiedEntity.data.whoCanReplySetting,
        ),
        poll: poll,
        language: _buildLanguageLabel(language),
      );

      final originalContentDelta = parseAndConvertDelta(
        modifiedEntity.data.richText?.content,
        modifiedEntity.data.content,
      );

      final originalMentions = _buildMentions(originalContentDelta);

      final removedMediaHashes = _buildRemovedMediaHashes(
        post: modifiedEntity,
        mediaAttachments: mediaAttachments.values.toList(),
      );

      await Future.wait([
        ref.read(ionConnectDeleteFileNotifierProvider.notifier).deleteMultiple(removedMediaHashes),
        _publishPost(
          postData,
          files: files,
          mentions: <RelatedPubkey>{...originalMentions, ...mentions}.toList(),
          quotedEvent: quotedEvent,
          parentEntity: parentEntity,
        ),
      ]);
    });
  }

  Future<void> softDelete({
    required EventReference eventReference,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final entity =
          await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
      if (entity is! ModifiablePostEntity) {
        throw UnsupportedEventReference(eventReference);
      }

      final postData = entity.data.copyWith(
        textContent: '',
        editingEndedAt: null,
        relatedHashtags: [],
        relatedPubkeys: [],
        quotedEvent: null,
        media: {},
        settings: null,
        expiration: null,
        richText: null,
        poll: null,
      );

      final contentDelta = parseAndConvertDelta(
        entity.data.richText?.content,
        entity.data.content,
      );

      final removedMediaHashes = _buildRemovedMediaHashes(post: entity, mediaAttachments: []);

      await Future.wait([
        ref.read(ionConnectDeleteFileNotifierProvider.notifier).deleteMultiple(removedMediaHashes),
        _publishPost(
          postData,
          mentions: _buildMentions(contentDelta),
          quotedEvent: entity.data.quotedEvent?.eventReference,
          parentEntity: entity.data.parentEvent?.eventReference != null
              ? await _getEntity(entity.data.parentEvent!.eventReference)
              : null,
        ),
      ]);
    });
  }

  Future<ModifiablePostEntity> _publishPost(
    ModifiablePostData postData, {
    EventReference? quotedEvent,
    IonConnectEntity? parentEntity,
    List<FileMetadata> files = const [],
    List<RelatedPubkey> mentions = const [],
  }) async {
    final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);

    final postEvent = await ionNotifier.sign(postData);
    final fileEvents = await Future.wait(files.map(ionNotifier.sign));

    final pubkeysToPublish = mentions.map((mention) => mention.value).toSet();
    final metadataBuilders = <EventsMetadataBuilder>[];

    if (quotedEvent != null) {
      pubkeysToPublish.add(quotedEvent.masterPubkey);
    } else if (parentEntity != null) {
      final rootRelatedEvent = postData.rootRelatedEvent;
      pubkeysToPublish.addAll([
        parentEntity.masterPubkey,
        if (rootRelatedEvent != null) rootRelatedEvent.eventReference.masterPubkey,
      ]);
      final rootRef = rootRelatedEvent?.eventReference;
      final rootEntity = (rootRef != null
              ? await ref.watch(
                  ionConnectEntityProvider(eventReference: rootRef).future,
                )
              : null) ??
          parentEntity;
      if (rootEntity is ModifiablePostEntity &&
          rootEntity.data.hasVerifiedUsersOnlyCanReplySettingOption) {
        final verifiedUserEventsMetadataBuilder =
            await ref.read(verifiedUserEventsMetadataBuilderProvider.future);
        metadataBuilders.add(verifiedUserEventsMetadataBuilder);
      }
    }

    final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);
    metadataBuilders.add(userEventsMetadataBuilder);

    await Future.wait([
      ionNotifier.sendEvents([...fileEvents, postEvent]),
      for (final pubkey in pubkeysToPublish)
        ionNotifier.sendEvent(
          postEvent,
          actionSource: ActionSourceUser(pubkey),
          metadataBuilders: metadataBuilders,
          cache: false,
        ),
    ]);

    return ModifiablePostEntity.fromEventMessage(postEvent);
  }

  EntityPublishedAt _buildEntityPublishedAt() {
    return EntityPublishedAt(value: DateTime.now().microsecondsSinceEpoch);
  }

  EntityEditingEndedAt _buildEditingEndedAt() {
    return EntityEditingEndedAt.build(
      ref.read(envProvider.notifier).get<int>(EnvVariable.EDIT_POST_ALLOWED_MINUTES),
    );
  }

  EntityExpiration? _buildExpiration() {
    if (createOption == CreatePostOption.story) {
      return EntityExpiration(
        value: DateTime.now()
            .add(
              Duration(
                hours: ref.read(envProvider.notifier).get<int>(EnvVariable.STORY_EXPIRATION_HOURS),
              ),
            )
            .microsecondsSinceEpoch,
      );
    }
    return null;
  }

  EntityLabel? _buildLanguageLabel(String? language) {
    if (language != null) {
      return EntityLabel(
        values: [language],
        namespace: EntityLabelNamespace.language,
      );
    }
    return null;
  }

  Future<({List<FileMetadata> files, Map<String, MediaAttachment> media})> _uploadMediaFiles({
    List<MediaFile>? mediaFiles,
  }) async {
    final files = <FileMetadata>[];
    final attachments = <MediaAttachment>[];
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      final mediaUploadService = ref.read(
        mediaUploadProvider(
          fileAlt: _getFileAlt().toShortString(),
          imageCompressionSettings: createOption != CreatePostOption.story
              ? const ImageCompressionSettings(shouldCompressGif: true)
              : const ImageCompressionSettings(),
        ),
      );

      final results = await Future.wait(
        mediaFiles.map(mediaUploadService.uploadMedia),
      );
      for (final result in results) {
        files.addAll(result.fileMetadatas);
        attachments.add(result.mediaAttachment);
      }
    }
    return (
      files: files,
      media: {for (final attachment in attachments) attachment.url: attachment}
    );
  }

  Future<IonConnectEntity> _getEntity(EventReference eventReference) async {
    final entity = await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
    if (entity == null) {
      throw EntityNotFoundException(eventReference);
    }

    if (entity is! ModifiablePostEntity && entity is! ArticleEntity && entity is! PostEntity) {
      throw UnsupportedParentEntity(entity);
    }
    return entity;
  }

  QuotedEvent _buildQuotedEvent(EventReference quotedEventReference) {
    return switch (quotedEventReference) {
      ReplaceableEventReference() => QuotedReplaceableEvent(eventReference: quotedEventReference),
      ImmutableEventReference() => QuotedImmutableEvent(eventReference: quotedEventReference),
      _ => throw UnsupportedEventReference(quotedEventReference)
    };
  }

  Future<RichText> _buildRichTextContentWithMediaLinks({
    required Delta content,
    required List<MediaAttachment> media,
  }) async {
    final contentWithMedia = await _buildContentWithMediaLinksDelta(
      content: content,
      media: media,
    );

    final richText = RichText(
      protocol: 'quill_delta',
      content: jsonEncode(contentWithMedia.toJson()),
    );

    return richText;
  }

  Future<Delta> _buildContentWithMediaLinksDelta({
    required Delta content,
    required List<MediaAttachment> media,
  }) async {
    final newContentDelta = withFlattenLinks(content);

    return Delta.fromOperations(
      media
          .map(
            (mediaItem) => Operation.insert(' ', {Attribute.link.key: mediaItem.url}),
          )
          .toList(),
    ).concat(newContentDelta);
  }

  List<RelatedEvent> _buildRelatedEvents(IonConnectEntity parentEntity) {
    final parentEventReference = parentEntity.toEventReference();

    final parentEntityData = switch (parentEntity) {
      ModifiablePostEntity() => parentEntity.data,
      PostEntity() => parentEntity.data,
      _ => null,
    };

    if (parentEntityData is! EntityDataWithRelatedEvents?) {
      throw UnsupportedParentEntity(parentEntity);
    }

    final rootParentRelatedEvent = parentEntityData?.rootRelatedEvent;

    if (parentEventReference is ReplaceableEventReference) {
      return [
        rootParentRelatedEvent ??
            RelatedReplaceableEvent(
              eventReference: parentEventReference,
              pubkey: parentEntity.masterPubkey,
              marker: RelatedEventMarker.root,
            ),
        RelatedReplaceableEvent(
          eventReference: parentEventReference,
          pubkey: parentEntity.masterPubkey,
          marker: RelatedEventMarker.reply,
        ),
      ];
    } else if (parentEventReference is ImmutableEventReference) {
      return [
        rootParentRelatedEvent ??
            RelatedImmutableEvent(
              eventReference: parentEventReference,
              pubkey: parentEntity.masterPubkey,
              marker: RelatedEventMarker.root,
            ),
        RelatedImmutableEvent(
          eventReference: parentEventReference,
          pubkey: parentEntity.masterPubkey,
          marker: RelatedEventMarker.reply,
        ),
      ];
    } else {
      throw UnsupportedParentEntity(parentEntity);
    }
  }

  List<RelatedPubkey> _buildMentions(Delta content) {
    return content.extractPubkeys().map((pubkey) => RelatedPubkey(value: pubkey)).toList();
  }

  Set<RelatedPubkey> _buildRelatedPubkeys({
    required List<RelatedPubkey> mentions,
    IonConnectEntity? parentEntity,
    EventReference? quotedEvent,
  }) {
    final allPubkeys = <RelatedPubkey>{...mentions};
    if (quotedEvent != null) {
      allPubkeys.add(RelatedPubkey(value: quotedEvent.masterPubkey));
    }

    if (parentEntity != null) {
      allPubkeys.add(RelatedPubkey(value: parentEntity.masterPubkey));
      final parentPubkeys = parentEntity is ModifiablePostEntity
          ? parentEntity.data.relatedPubkeys
          : parentEntity is PostEntity
              ? parentEntity.data.relatedPubkeys
              : null;
      if (parentPubkeys != null) {
        allPubkeys.addAll(parentPubkeys);
      }
    }

    return allPubkeys;
  }

  List<String> _buildRemovedMediaHashes({
    required ModifiablePostEntity post,
    required List<MediaAttachment> mediaAttachments,
  }) {
    final originalMediaHashes = post.data.media.values.map((e) => e.originalFileHash).toSet();
    final attachedMediaHashes = mediaAttachments.map((e) => e.originalFileHash).toSet();
    return originalMediaHashes.difference(attachedMediaHashes).toList();
  }

  FileAlt _getFileAlt() {
    return switch (createOption) {
      CreatePostOption.video => FileAlt.video,
      CreatePostOption.story => FileAlt.story,
      _ => FileAlt.post
    };
  }

  List<String> _getTopicsFromParentAndQuoted(
    IonConnectEntity? parentEntity,
    IonConnectEntity? quotedEntity,
  ) {
    if (parentEntity == null && quotedEntity == null) {
      return [];
    }
    final parentTopics = RelatedHashtag.extractTopics(_getRelatedHashtags(parentEntity));
    final quotedTopics = RelatedHashtag.extractTopics(_getRelatedHashtags(quotedEntity));
    return {
      ...parentTopics,
      ...quotedTopics,
    }.toList();
  }

  List<RelatedHashtag>? _getRelatedHashtags(IonConnectEntity? entity) {
    return switch (entity) {
      ModifiablePostEntity() => entity.data.relatedHashtags,
      PostEntity() => entity.data.relatedHashtags,
      ArticleEntity() => entity.data.relatedHashtags,
      _ => null,
    };
  }

  Future<void> _updateInterests(ModifiablePostEntity post) async {
    final tags = post.data.relatedHashtags ?? [];
    if (tags.isEmpty) return;

    final interaction = switch (post.data) {
      _ when post.data.quotedEvent != null => FeedInterestInteraction.quote,
      _ when post.data.relatedEvents != null => switch (post.data.relatedEvents) {
          [final a, final b] when a.eventReference == b.eventReference =>
            FeedInterestInteraction.addTopReply,
          _ => FeedInterestInteraction.addNestedReply,
        },
      _ => FeedInterestInteraction.createPost,
    };

    final interactionCategories = tags.map((tag) => tag.value).toList();

    await ref
        .read(feedUserInterestsNotifierProvider.notifier)
        .updateInterests(interaction, interactionCategories);
  }
}
