// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_media_provider.r.g.dart';

@riverpod
Future<List<GroupMediaItem>> groupMedia(
  Ref ref,
  String conversationId,
) async {
  final messagesStream = ref.watch(conversationMessageDaoProvider).getMessages(conversationId);

  final messagesByDate = await messagesStream.first;
  final allMedia = <GroupMediaItem>[];

  // Flatten all messages from all dates
  for (final messages in messagesByDate.values) {
    for (final eventMessage in messages) {
      try {
        final entity = EncryptedGroupMessageEntity.fromEventMessage(eventMessage);
        final eventReference = entity.toEventReference();
        final publishedAt = entity.data.publishedAt.value;

        for (final media in entity.data.media.values) {
          allMedia.add(
            GroupMediaItem(
              media: media,
              eventReference: eventReference,
              publishedAt: publishedAt,
            ),
          );
        }
      } catch (_) {
        // Skip messages that can't be parsed as EncryptedGroupMessageEntity
        continue;
      }
    }
  }

  // Sort by publishedAt descending (newest first)
  allMedia.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  return allMedia;
}

class GroupMediaItem {
  GroupMediaItem({
    required this.media,
    required this.eventReference,
    required this.publishedAt,
  });

  final MediaAttachment media;
  final EventReference eventReference;
  final int publishedAt;

  bool get isVisualMedia {
    final mediaType = media.mediaTypeEncrypted ?? media.mediaType;
    return mediaType == MediaType.image || mediaType == MediaType.video;
  }

  bool get isAudio {
    final mediaType = media.mediaTypeEncrypted ?? media.mediaType;
    return mediaType == MediaType.audio;
  }

  bool get isFile {
    final mediaType = media.mediaTypeEncrypted ?? media.mediaType;
    return mediaType == MediaType.unknown;
  }
}

@riverpod
Future<List<GroupMediaItem>> groupMediaItems(
  Ref ref,
  String conversationId,
) async {
  final allMedia = await ref.watch(groupMediaProvider(conversationId).future);
  return allMedia.where((GroupMediaItem item) => item.isVisualMedia).toList();
}

@riverpod
Future<List<GroupMediaItem>> groupVoiceItems(
  Ref ref,
  String conversationId,
) async {
  final allMedia = await ref.watch(groupMediaProvider(conversationId).future);
  return allMedia.where((GroupMediaItem item) => item.isAudio).toList();
}

@riverpod
Future<List<GroupMediaItem>> groupFilesItems(
  Ref ref,
  String conversationId,
) async {
  final allMedia = await ref.watch(groupMediaProvider(conversationId).future);
  return allMedia.where((GroupMediaItem item) => item.isFile).toList();
}
