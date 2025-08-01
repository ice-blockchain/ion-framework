// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/components/text_editor/utils/extract_tags.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/create_article/providers/draft_article_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests.f.dart';
import 'package:ion/app/features/feed/data/models/feed_interests_interaction.dart';
import 'package:ion/app/features/feed/data/models/who_can_reply_settings_option.f.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/features/feed/providers/media_upload_provider.r.dart';
import 'package:ion/app/features/gallery/providers/gallery_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/color_label.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_settings.dart';
import 'package:ion/app/features/ion_connect/model/entity_editing_ended_at.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_delete_file_notifier.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
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

      final (imageUrl, updatedContent) = await (mainImageFuture, contentFuture).wait;

      final richText = RichText(
        protocol: 'quill_delta',
        content: jsonEncode(updatedContent.toJson()),
      );

      if (topics.isEmpty) {
        topics.add(FeedInterests.unclassified);
      }
      final relatedHashtags = [
        ...topics.map((topic) => RelatedHashtag(value: topic)),
        ...extractTags(updatedContent).map((tag) => RelatedHashtag(value: tag)),
      ];

      final editingEndedAt = EntityEditingEndedAt.build(
        ref.read(envProvider.notifier).get<int>(EnvVariable.EDIT_POST_ALLOWED_MINUTES),
      );

      final mentions = _buildMentions(updatedContent);

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
        richText: richText,
        editingEndedAt: editingEndedAt,
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
        richText: null,
        editingEndedAt: null,
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

      final contentString = jsonEncode(updatedContent.toJson());

      final richText = RichText(
        protocol: 'quill_delta',
        content: contentString,
      );

      if (topics.contains(FeedInterests.unclassified) && topics.length > 1) {
        topics.remove(FeedInterests.unclassified);
      } else if (topics.isEmpty) {
        topics.add(FeedInterests.unclassified);
      }
      final relatedHashtags = [
        ...topics.map((topic) => RelatedHashtag(value: topic)),
        ...extractTags(updatedContent).map((tag) => RelatedHashtag(value: tag)),
      ];

      final modifiedMedia = Map<String, MediaAttachment>.from(mediaAttachments);
      for (final attachment in updatedMediaAttachments) {
        modifiedMedia[attachment.url] = attachment;
      }

      final unusedMediaFileHashes = <String>[];

      final cleanedMedia = Map<String, MediaAttachment>.from(modifiedEntity.data.media);

      modifiedEntity.data.media.forEach((url, attachment) {
        final urlInContent = contentString.contains(url);
        final urlToCheck = url.replaceAll('url ', '');
        if (!urlInContent && (originalImageUrl != null && urlToCheck != originalImageUrl)) {
          cleanedMedia.remove(url);
          unusedMediaFileHashes.add(attachment.originalFileHash);
        }
      });

      for (final attachment in updatedMediaAttachments) {
        cleanedMedia[attachment.url] = attachment;
      }

      final mentions = _buildMentions(updatedContent);

      final originalContentDelta = parseAndConvertDelta(
        modifiedEntity.data.richText?.content,
        modifiedEntity.data.content,
      );

      final originalMentions = _buildMentions(originalContentDelta);

      final articleData = modifiedEntity.data.copyWith(
        title: title,
        summary: summary,
        image: imageUrlToUpload,
        textContent: '',
        media: cleanedMedia,
        relatedHashtags: relatedHashtags,
        relatedPubkeys: mentions,
        settings: EntityDataWithSettings.build(whoCanReply: whoCanReply),
        colorLabel: imageColor != null ? ColorLabel(value: imageColor) : null,
        richText: richText,
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

    final articleEvent = await ionNotifier.sign(articleData);
    final fileEvents = await Future.wait(files.map(ionNotifier.sign));

    final pubkeysToPublish = mentions.map((mention) => mention.value).toSet();

    final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);

    await Future.wait([
      ionNotifier.sendEvents([...fileEvents, articleEvent]),
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
          alt: FileAlt.article,
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
          fileAlt: FileAlt.article,
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

    return withFlattenLinks(updatedContent);
  }

  List<RelatedPubkey> _buildMentions(Delta content) {
    return content.extractPubkeys().map((pubkey) => RelatedPubkey(value: pubkey)).toList();
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

  Future<String> getOriginalAssetPath(String assetId) async {
    final assetEntity = await ref.read(assetEntityProvider(assetId).future);

    if (assetEntity == null) {
      throw AssetEntityFileNotFoundException(assetId: assetId);
    }

    final isGif = await isGifAsset(assetEntity);
    if (isGif) {
      final file = await assetEntity.originFile;
      if (file == null) {
        throw AssetEntityFileNotFoundException(assetId: assetId);
      }
      return file.path;
    }

    final defaultPath = await ref.read(assetFilePathProvider(assetId).future);
    if (defaultPath == null || defaultPath.isEmpty) {
      throw AssetEntityFileNotFoundException(assetId: assetId);
    }

    return defaultPath;
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
}
