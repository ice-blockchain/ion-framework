// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_media_provider.r.g.dart';

@riverpod
class GroupMedia extends _$GroupMedia {
  @override
  Stream<List<GroupMediaItem>> build(String conversationId) async* {
    final messagesStream = ref.watch(conversationMessageDaoProvider).getMessages(conversationId);

    await for (final messagesByDate in messagesStream) {
      final allMedia = <GroupMediaItem>[];

      // Flatten all messages from all dates
      for (final messages in messagesByDate.values) {
        for (final eventMessage in messages) {
          try {
            final entity = EncryptedGroupMessageEntity.fromEventMessage(eventMessage);
            final visualMedias = entity.data.visualMedias;

            for (final media in visualMedias) {
              allMedia.add(
                GroupMediaItem(
                  media: media,
                  eventReference: entity.toEventReference(),
                  publishedAt: entity.data.publishedAt.value,
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

      yield allMedia;
    }
  }
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
}
