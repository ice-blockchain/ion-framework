// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/components/text_editor/utils/delta_bridge.dart';
import 'package:ion/app/components/text_editor/utils/extract_tags.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/create_article/providers/draft_article_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests_interaction.dart';
import 'package:ion/app/features/feed/data/models/who_can_reply_settings_option.f.dart';
import 'package:ion/app/features/feed/providers/content_conversion.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/media_upload_provider.r.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_settings.dart';
import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_delete_file_notifier.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/user/providers/ugc_counter_provider.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/markdown/quill.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/image_path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_article_provider.r.g.dart';

final _createArticleNotifierStreamController = StreamController<IonConnectEntity>.broadcast();

@riverpod
Raw<Stream<IonConnectEntity>> createArticleNotifierStream(Ref ref) {
  return _createArticleNotifierStreamController.stream;
}

enum CreateArticleOption {
  plain,
  softDelete,
  modify;
}

@riverpod
class CreateArticle extends _$CreateArticle {
  @override
  FutureOr<void> build(CreateArticleOption createOption) {}

  Future<void> create({
    required Delta content,
    required WhoCanReplySettingsOption whoCanReply,
    required Set<String> topics,
    String? title,
    String? summary,
    String? coverImagePath,
    DateTime? publishedAt,
    List<String>? mediaIds,
    String? imageColor,
    String? language,
    int? ugcCounter,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final files = <FileMetadata>[];
      final mediaAttachments = <MediaAttachment>[];

      final mainImageFuture = _uploadCoverImage(coverImagePath, files, mediaAttachments);
      final contentFuture = _prepareContent(
        content: content,
        mediaIds: mediaIds,
        files: files,
        mediaAttachments: mediaAttachments,
      );

      final ugcSerialLabel = await _buildUgcSerialLabel(ugcCounter: ugcCounter);

      final (imageUrl, updatedContent) = await (mainImageFuture, contentFuture).wait;

      final preparedContent = _normalizeContentForStorage(updatedContent);
      final markdownContent = preparedContent.markdown;
      final mentions = preparedContent.mentions;

      if (topics.isEmpty) {
        topics.add(FeedInterests.unclassified);
      }
      final relatedHashtags = _buildRelatedHashtags(topics, preparedContent.content);

      final articleData = ArticleData.fromData(
        title: title,
        summary: summary,
        image: imageUrl,
        media: {
          for (final attachment in mediaAttachments) attachment.url: attachment,
        },
        relatedHashtags: relatedHashtags,
        relatedPubkeys: mentions,
        publishedAt: publishedAt?.microsecondsSinceEpoch,
        settings: EntityDataWithSettings.build(whoCanReply: whoCanReply),
        imageColor: imageColor,
        textContent: markdownContent,
        language: _buildLanguageLabel(language),
        mentionMarketCapLabel: _buildMentionMarketCapLabel(preparedContent.content),
        ugcSerial: ugcSerialLabel,
      );

      final article = await _sendArticleEntities(
        articleData,
        files: files,
        mentions: mentions,
      );

      _createArticleNotifierStreamController.add(article);

      ref.read(draftArticleProvider.notifier).clear();

      await _updateInterests(article);
    });
  }

  Future<void> softDelete({
    required EventReference eventReference,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final entity =
          await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
      if (entity is! ArticleEntity) {
        throw UnsupportedEventReference(eventReference);
      }

      final articleData = entity.data.copyWith(
        title: null,
        summary: null,
        image: null,
        textContent: '',
        relatedHashtags: [],
        relatedPubkeys: [],
        media: {},
        colorLabel: null,
        settings: null,
        editingEndedAt: null,
        language: null,
        mentionMarketCapLabel: null,
        ugcSerial: null,
      );

      final media = entity.data.media.values;
      final fileHashes = media.map((e) => e.originalFileHash).toList();

      final contentDelta = parseAndConvertDelta(
        entity.data.richText?.content,
        entity.data.content,
      );

      await Future.wait([
        ref.read(ionConnectDeleteFileNotifierProvider.notifier).deleteMultiple(fileHashes),
        _sendArticleEntities(articleData, mentions: _buildMentions(contentDelta)),
      ]);
    });
  }

  Future<void> modify({
    required EventReference eventReference,
    required Delta content,
    required WhoCanReplySettingsOption whoCanReply,
    required Set<String> topics,
    String? title,
    String? summary,
    String? coverImagePath,
    String? originalImageUrl,
    Map<String, MediaAttachment> mediaAttachments = const {},
    String? imageColor,
    String? language,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final modifiedEntity =
          await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
      if (modifiedEntity is! ArticleEntity) {
        throw UnsupportedEventReference(eventReference);
      }

      final files = <FileMetadata>[];
      final updatedMediaAttachments = <MediaAttachment>[];

      final String? imageUrlToUpload;

      if (originalImageUrl != null) {
        imageUrlToUpload = originalImageUrl;
      } else {
        imageUrlToUpload = await _uploadCoverImage(coverImagePath, files, updatedMediaAttachments);
      }

      final updatedContent = await _prepareContent(
        content: content,
        files: files,
        mediaAttachments: updatedMediaAttachments,
      );

      final preparedContent = _normalizeContentForStorage(updatedContent);
      final markdownContent = preparedContent.markdown;
      final mentions = preparedContent.mentions;

      if (topics.contains(FeedInterests.unclassified) && topics.length > 1) {
        topics.remove(FeedInterests.unclassified);
      } else if (topics.isEmpty) {
        topics.add(FeedInterests.unclassified);
      }
      final relatedHashtags = _buildRelatedHashtags(topics, preparedContent.content);

      final modifiedMedia = Map<String, MediaAttachment>.from(mediaAttachments);
      for (final attachment in updatedMediaAttachments) {
        modifiedMedia[attachment.url] = attachment;
      }

      final cleanedMedia = _cleanMediaAttachments(
        existingMedia: modifiedEntity.data.media,
        modifiedMedia: modifiedMedia,
        content: preparedContent.content,
        originalImageUrl: originalImageUrl,
      );

      final unusedMediaFileHashes = _getUnusedMediaHashes(
        existingMedia: modifiedEntity.data.media,
        cleanedMedia: cleanedMedia,
      );

      final originalContentDelta = parseAndConvertDelta(
        modifiedEntity.data.richText?.content,
        modifiedEntity.data.content,
      );

      final originalMentions = _buildMentions(originalContentDelta);

      final articleData = modifiedEntity.data.copyWith(
        title: title,
        summary: summary,
        image: imageUrlToUpload,
        textContent: markdownContent,
        media: cleanedMedia,
        relatedHashtags: relatedHashtags,
        relatedPubkeys: mentions,
        settings: EntityDataWithSettings.build(whoCanReply: whoCanReply),
        colorLabel: imageColor != null
            ? EntityLabel(
                values: [LabelValue(value: imageColor)],
                namespace: EntityLabelNamespace.color,
              )
            : null,
        language: _buildLanguageLabel(language),
        mentionMarketCapLabel: _buildMentionMarketCapLabel(preparedContent.content),
      );

      if (unusedMediaFileHashes.isNotEmpty) {
        await ref
            .read(ionConnectDeleteFileNotifierProvider.notifier)
            .deleteMultiple(unusedMediaFileHashes);
      }
      await _sendArticleEntities(
        articleData,
        files: files,
        mentions: <RelatedPubkey>{...originalMentions, ...mentions}.toList(),
      );
      ref.read(draftArticleProvider.notifier).clear();
    });
  }

  Future<ArticleEntity> _sendArticleEntities(
    ArticleData articleData, {
    List<FileMetadata> files = const [],
    List<RelatedPubkey> mentions = const [],
  }) async {
    final ionNotifier = ref.read(ionConnectNotifierProvider.notifier);
    final communityTokenDefinitionRepository =
        await ref.read(communityTokenDefinitionRepositoryProvider.future);

    final articleEvent = await ionNotifier.sign(articleData);
    final fileEvents = await Future.wait(files.map(ionNotifier.sign));

    final pubkeysToPublish = mentions.map((mention) => mention.value).toSet();

    final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);

    final tokenDefinition = _buildArticleTokenDefinition(articleData);
    final tokenDefinitionEvent = await ionNotifier.sign(tokenDefinition);

    await Future.wait([
      ionNotifier.sendEvents([...fileEvents, articleEvent, tokenDefinitionEvent]),
      communityTokenDefinitionRepository.cacheTokenDefinitionReference(tokenDefinitionEvent),
      for (final pubkey in pubkeysToPublish)
        ionNotifier.sendEvent(
          articleEvent,
          actionSource: ActionSourceUser(pubkey),
          metadataBuilders: [userEventsMetadataBuilder],
          cache: false,
        ),
    ]);

    return ArticleEntity.fromEventMessage(articleEvent);
  }

  Future<String?> _uploadCoverImage(
    String? imagePath,
    List<FileMetadata> files,
    List<MediaAttachment> mediaAttachments,
  ) async {
    if (imagePath == null) return null;

    final uploadResult = await _uploadImage(imagePath);
    files.add(uploadResult.fileMetadata);
    mediaAttachments.add(uploadResult.mediaAttachment);
    return uploadResult.mediaAttachment.url;
  }

  Future<UploadResult> _uploadImage(String imagePath) async {
    final imageCompressor = ref.read(imageCompressorProvider);

    final file = MediaFile(
      path: imagePath,
    );
    final compressedImage = await imageCompressor.compress(file);

    final result = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
          compressedImage,
          alt: FileAlt.article.toShortString(),
        );
    return result;
  }

  Future<Delta> _prepareContent({
    required Delta content,
    required List<FileMetadata> files,
    required List<MediaAttachment> mediaAttachments,
    List<String>? mediaIds,
  }) async {
    final uploadedUrls = <String, String>{};

    var updatedContent = content;

    final draftArticle = ref.read(draftArticleProvider);
    final codeBlocks = draftArticle.codeBlocks;

    updatedContent = Delta.fromOperations(
      updatedContent.toList().map((operation) {
        if (operation.isInsert && operation.data is Map<String, dynamic>) {
          final mapData = operation.data! as Map<String, dynamic>;
          if (mapData.containsKey('text-editor-code')) {
            final blockId = mapData['text-editor-code'];
            if (codeBlocks.containsKey(blockId)) {
              return Operation.insert({
                'text-editor-code': codeBlocks[blockId],
              });
            }
          }
        }
        return operation;
      }).toList(),
    );

    if (mediaIds != null && mediaIds.isNotEmpty) {
      final mediaUploadService = ref.read(
        mediaUploadProvider(
          fileAlt: FileAlt.article.toShortString(),
        ),
      );

      final mediaFiles = await Future.wait(
        mediaIds.map((assetId) async {
          final assetEntity = await ref.read(assetEntityProvider(assetId).future);
          if (assetEntity == null) {
            throw AssetEntityFileNotFoundException(assetId: assetId);
          }

          final assetFileFuture = getAssetFile(assetEntity);
          final (mimeType, file) = await (assetEntity.mimeTypeAsync, assetFileFuture).wait;

          if (file == null) {
            throw AssetEntityFileNotFoundException(assetId: assetId);
          }

          return MediaFile(
            path: file.path,
            height: assetEntity.height,
            width: assetEntity.width,
            mimeType: mimeType,
            duration: assetEntity.duration,
          );
        }),
      );

      await Future.wait(
        mediaFiles.map((mediaFile) async {
          final assetId = mediaIds[mediaFiles.indexOf(mediaFile)];
          final (:fileMetadatas, :mediaAttachment) =
              await mediaUploadService.uploadMedia(mediaFile);

          uploadedUrls[assetId] = mediaAttachment.url;
          files.addAll(fileMetadatas);
          mediaAttachments.add(mediaAttachment);
        }),
      );
      updatedContent = _replaceImagePathsWithUrls(updatedContent, uploadedUrls);
    }

    // Don't flatten links - keep URLs as plain text for backward compatibility
    return updatedContent;
  }

  List<RelatedPubkey> _buildMentions(Delta content) {
    return content
        .extractMentionsWithFlags()
        .map((mention) => RelatedPubkey(value: mention.pubkey))
        .toSet()
        .toList();
  }

  EntityLabel? _buildMentionMarketCapLabel(Delta content) {
    final counters = <String, int>{};
    final labelEntries = <(String pubkey, int instance)>[];

    // Iterate using shared logic (guarantees symmetry with load flow)
    content.forEachMention((pubkey, {required bool showMarketCap}) {
      final currentInstance = counters[pubkey] ?? 0;
      counters[pubkey] = currentInstance + 1;

      if (showMarketCap) {
        labelEntries.add((pubkey, currentInstance));
      }
    });

    if (labelEntries.isEmpty) {
      return null;
    }

    // Build LabelValue list with value and additional elements
    final values = labelEntries
        .map(
          (entry) => LabelValue(
            value: entry.$1, // pubkey
            additionalElements: [entry.$2.toString()], // instance number
          ),
        )
        .toList();

    return EntityLabel(
      values: values,
      namespace: EntityLabelNamespace.mentionMarketCap,
    );
  }

  // Builds relatedHashtags by combining:
  // 1. User-selected topics (categories like "Technology", "Sports")
  // 2. Hashtags/cashtags extracted from content text (#flutter, $BTC)
  List<RelatedHashtag> _buildRelatedHashtags(Set<String> topics, Delta content) {
    return [
      ...topics.map((topic) => RelatedHashtag(value: topic)),
      ...extractTags(content).map((tag) => RelatedHashtag(value: tag)),
    ];
  }

  ({
    Delta content,
    String markdown,
    List<RelatedPubkey> mentions,
  }) _normalizeContentForStorage(Delta rawContent) {
    final contentWithAttributes = DeltaBridge.normalizeToAttributeFormat(rawContent);
    final markdown = convertDeltaToMarkdown(contentWithAttributes);
    final mentions = _buildMentions(contentWithAttributes);
    return (
      content: contentWithAttributes,
      markdown: markdown,
      mentions: mentions,
    );
  }

  Map<String, MediaAttachment> _cleanMediaAttachments({
    required Map<String, MediaAttachment> existingMedia,
    required Map<String, MediaAttachment> modifiedMedia,
    required Delta content,
    String? originalImageUrl,
  }) {
    final cleanedMedia = Map<String, MediaAttachment>.from(existingMedia);
    for (final entry in modifiedMedia.entries) {
      cleanedMedia[entry.key] = entry.value;
    }

    final contentJson = jsonEncode(content.toJson());
    existingMedia.forEach((url, attachment) {
      final urlInContent = contentJson.contains(url);
      final urlToCheck = url.replaceAll('url ', '');
      final isInModifiedMedia = modifiedMedia.containsKey(url);
      final isOriginalImage = originalImageUrl != null && urlToCheck == originalImageUrl;

      if (!urlInContent && !isInModifiedMedia && !isOriginalImage) {
        cleanedMedia.remove(url);
      }
    });

    return cleanedMedia;
  }

  List<String> _getUnusedMediaHashes({
    required Map<String, MediaAttachment> existingMedia,
    required Map<String, MediaAttachment> cleanedMedia,
  }) {
    final existingHashes = existingMedia.values.map((e) => e.originalFileHash).toSet();
    final cleanedHashes = cleanedMedia.values.map((e) => e.originalFileHash).toSet();
    return existingHashes.difference(cleanedHashes).toList();
  }

  Delta _replaceImagePathsWithUrls(
    Delta content,
    Map<String, String> uploadedUrls,
  ) {
    return Delta.fromOperations(
      content.map((operation) {
        final operationData = operation.data;
        if (operation.isInsert &&
            operationData is Map<String, dynamic> &&
            operationData.containsKey(textEditorSingleImageKey) &&
            operationData[textEditorSingleImageKey] != null &&
            uploadedUrls.containsKey(operationData[textEditorSingleImageKey])) {
          return Operation.insert(
            ' ',
            {textEditorSingleImageKey: uploadedUrls[operationData[textEditorSingleImageKey]]},
          );
        }
        return operation;
      }).toList(),
    );
  }

  Future<void> _updateInterests(ArticleEntity article) async {
    final tags = article.data.relatedHashtags ?? [];
    final interactionCategories = tags.map((tag) => tag.value).toList();

    if (interactionCategories.isNotEmpty) {
      await ref
          .read(feedUserInterestsNotifierProvider.notifier)
          .updateInterests(FeedInterestInteraction.createArticle, interactionCategories);
    }
  }

  Future<EntityLabel> _buildUgcSerialLabel({int? ugcCounter}) async {
    try {
      final counter = ugcCounter ?? await ref.refresh(ugcCounterProvider().future);
      if (counter == null) {
        throw UgcCounterFetchException();
      }
      return EntityLabel(
        values: [LabelValue(value: (counter + 1).toString())],
        namespace: EntityLabelNamespace.ugcSerial,
      );
    } on EventCountException {
      rethrow;
    }
  }

  EntityLabel? _buildLanguageLabel(String? language) {
    if (language != null) {
      return EntityLabel(
        values: [LabelValue(value: language)],
        namespace: EntityLabelNamespace.language,
      );
    }
    return null;
  }

  CommunityTokenDefinition _buildArticleTokenDefinition(ArticleData articleData) {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    return CommunityTokenDefinitionIon.fromEventReference(
      eventReference: ReplaceableEventReference(
        masterPubkey: currentPubkey,
        kind: ArticleEntity.kind,
        dTag: articleData.replaceableEventId.value,
      ),
      kind: ArticleEntity.kind,
      type: CommunityTokenDefinitionIonType.original,
    );
  }
}
