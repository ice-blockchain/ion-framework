// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/search/model/chat_search_result_item.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_messages_search_provider.r.g.dart';

@riverpod
Future<List<ChatSearchResultItem>?> chatMessagesSearch(Ref ref, String query) async {
  if (query.isEmpty) return null;

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserMasterPubkey == null) return null;

  final caseInsensitiveQuery = query.toLowerCase();

  final eventMessageDao = ref.watch(eventMessageDaoProvider);

  final searchResults = await eventMessageDao.search(caseInsensitiveQuery);

  final entities = searchResults.map(ReplaceablePrivateDirectMessageEntity.fromEventMessage);

  // Database already returns results sorted by createdAt DESC, no need to sort again
  final messages = entities.toList();

  // Extract unique receiver pubkeys and filter out nulls early
  final receiverMasterPubkeys = <String>{};
  final messagePubkeyMap = <ReplaceablePrivateDirectMessageEntity, String>{};

  for (final message in messages) {
    final receiverMasterPubkey = message.allPubkeys.firstWhereOrNull(
      (key) => key != currentUserMasterPubkey,
    );
    if (receiverMasterPubkey != null) {
      receiverMasterPubkeys.add(receiverMasterPubkey);
      messagePubkeyMap[message] = receiverMasterPubkey;
    }
  }

  if (receiverMasterPubkeys.isEmpty) {
    return [];
  }

  final metadataExpiration =
      ref.read(envProvider.notifier).get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES);

  // Load all user preview data upfront and cache in a map
  final userPreviewDataFutures = receiverMasterPubkeys.map(
    (pubkey) => ref
        .watch(
          userPreviewDataProvider(
            pubkey,
            expirationDuration: Duration(minutes: metadataExpiration),
          ).future,
        )
        .then((data) => MapEntry(pubkey, data)),
  );

  final userPreviewDataEntries = await Future.wait(userPreviewDataFutures);

  final userPreviewDataMap = {
    for (final entry in userPreviewDataEntries)
      if (entry.value != null) entry.key: entry.value!,
  };

  // Build results using cached user preview data
  final result = <ChatSearchResultItem>[];

  for (final message in messages) {
    final receiverMasterPubkey = messagePubkeyMap[message];
    if (receiverMasterPubkey == null) continue;

    final userPreviewData = userPreviewDataMap[receiverMasterPubkey];
    if (userPreviewData == null) continue;

    result.add(
      ChatSearchResultItem(
        masterPubkey: userPreviewData.masterPubkey,
        lastMessageContent: message.data.content,
      ),
    );
  }

  return result;
}
