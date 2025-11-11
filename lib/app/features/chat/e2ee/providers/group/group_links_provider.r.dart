// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/services/text_parser/model/text_matcher.dart';
import 'package:ion/app/services/text_parser/text_parser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'group_links_provider.r.g.dart';

@riverpod
Future<List<GroupLinkItem>> groupLinks(
  Ref ref,
  String conversationId,
) async {
  final messagesStream = ref.watch(conversationMessageDaoProvider).getMessages(conversationId);

  // Get the latest snapshot from the stream
  final messagesByDate = await messagesStream.first;
  final allLinks = <GroupLinkItem>[];

  // Flatten all messages from all dates
  for (final messages in messagesByDate.values) {
    for (final eventMessage in messages) {
      try {
        final entity = EncryptedGroupMessageEntity.fromEventMessage(eventMessage);
        final eventReference = entity.toEventReference();
        final publishedAt = entity.data.publishedAt.value;

        // Extract links from content
        final content = entity.data.content;
        if (content.isNotEmpty) {
          final textParser = TextParser(matchers: {const UrlMatcher()});
          final parsed = textParser.parse(content, onlyMatches: true);
          final links = parsed
              .where((match) => match.matcher is UrlMatcher)
              .map((match) => match.text)
              .toSet(); // Use Set to avoid duplicates

          for (final link in links) {
            // Exclude media URLs (they're already in media attachments)
            final isMediaUrl = entity.data.media.values.any(
              (media) => media.url == link || media.thumb == link || media.image == link,
            );
            if (!isMediaUrl) {
              allLinks.add(
                GroupLinkItem(
                  url: link,
                  eventReference: eventReference,
                  publishedAt: publishedAt,
                ),
              );
            }
          }
        }
      } catch (_) {
        // Skip messages that can't be parsed as EncryptedGroupMessageEntity
        continue;
      }
    }
  }

  // Sort by publishedAt descending (newest first)
  allLinks.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  return allLinks;
}

class GroupLinkItem {
  GroupLinkItem({
    required this.url,
    required this.eventReference,
    required this.publishedAt,
  });

  final String url;
  final EventReference eventReference;
  final int publishedAt;
}
