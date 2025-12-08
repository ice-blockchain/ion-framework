// SPDX-License-Identifier: ice License 1.0
// ignore_for_file: provider_parameters
import 'dart:async';
import 'dart:io';

import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_message_load_media_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/e2ee_delete_event_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/database/converters/event_reference_converter.d.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/url.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_media_chat_message_provider.r.g.dart';

@riverpod
Future<void> deleteMediaChatMessage(
  Ref ref, {
  required EventMessage eventMessage,
  required MediaAttachment mediaToDelete,
}) async {
  final entity = ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage);
  final eventReference = entity.toEventReference();

  final remainingMedia = entity.data.visualMedias
      .where((e) => !entity.data.visualMedias.any((c) => c.thumb == e.url && c.url != e.url))
      .where((media) => media.url != mediaToDelete.url)
      .toList();

  final hasContent = entity.data.content.trim().isNotEmpty;
  final hasQuotedEvent = entity.data.quotedEvent != null;

  if (remainingMedia.isEmpty && !hasContent && !hasQuotedEvent) {
    ref.read(
      e2eeDeleteMessageProvider(
        forEveryone: true,
        messageEvents: [eventMessage],
      ),
    );
  }

  final mediaRecords = await (ref.read(chatDatabaseProvider).select(
            ref.read(chatDatabaseProvider).messageMediaTable,
          )..where(
          (MessageMediaTable table) => table.messageEventReference
              .equals(const EventReferenceConverter().toSql(eventReference)),
        ))
      .get();

  final mediaUrlToCacheKey = <String, String?>{};
  for (final record in mediaRecords) {
    if (record.remoteUrl != null) {
      mediaUrlToCacheKey[record.remoteUrl!] = record.cacheKey;
    }
  }

  final mediaFiles = <MediaFile>[];
  for (final media in remainingMedia) {
    final isRemoteUrl = isNetworkUrl(media.url);
    String filePath;

    if (isRemoteUrl) {
      final cacheKey = mediaUrlToCacheKey[media.url];
      File? cachedFile;

      if (cacheKey != null) {
        cachedFile = await ref.read(mediaServiceProvider).getFileFromAppDirectory(cacheKey);
      }

      if (cachedFile == null) {
        final fileInfo =
            await ref.read(ionConnectFileCacheServiceProvider).getFileFromCache(media.url);

        if (fileInfo != null) {
          cachedFile = fileInfo.file;
        }
      }

      cachedFile ??= await ref.read(
        chatMessageLoadMediaProvider(
          entity: entity,
          mediaAttachment: media,
          loadThumbnail: false,
          cacheKey: cacheKey,
        ),
      );

      if (cachedFile == null) {
        continue;
      }

      filePath = cachedFile.path;
    } else {
      filePath = media.url;
    }

    int? height;
    int? width;
    if (media.dimension != null) {
      final dimensions = media.dimension!.split('x');
      if (dimensions.length == 2) {
        height = int.tryParse(dimensions[0]);
        width = int.tryParse(dimensions[1]);
      }
    }

    mediaFiles.add(
      MediaFile(
        path: filePath,
        mimeType: media.originalMimeType,
        originalMimeType: media.originalMimeType,
        height: height,
        width: width,
      ),
    );
  }

  unawaited(
    ref.read(sendE2eeChatMessageServiceProvider).sendMessage(
          content: entity.data.content,
          conversationId: entity.data.conversationId,
          participantsMasterPubkeys: entity.allPubkeys,
          editedMessage: eventMessage,
          quotedEvent: entity.data.quotedEvent,
          quotedEventKind: entity.data.quotedEventKind,
          mediaFiles: mediaFiles,
        ),
  );
}
