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

String? _getReceiverPubkey(
  ReplaceablePrivateDirectMessageEntity message,
  String currentUserMasterPubkey,
) =>
    message.allPubkeys.firstWhereOrNull((key) => key != currentUserMasterPubkey);

@riverpod
Future<List<ChatSearchResultItem>?> chatMessagesSearch(Ref ref, String query) async {
  if (query.isEmpty) return null;

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserMasterPubkey == null) return null;

  final caseInsensitiveQuery = query.toLowerCase();
  final eventMessageDao = ref.watch(eventMessageDaoProvider);

  final searchResults = await eventMessageDao.search(caseInsensitiveQuery);

  final messages = searchResults.map(ReplaceablePrivateDirectMessageEntity.fromEventMessage);

  // Extract unique receiver pubkeys and filter out nulls early
  final messagePubkeyMap = <ReplaceablePrivateDirectMessageEntity, String>{
    for (final message in messages)
      if (_getReceiverPubkey(message, currentUserMasterPubkey) case final receiverPubkey?)
        message: receiverPubkey,
  };
  final receiverMasterPubkeys = messagePubkeyMap.values.toSet();

  if (receiverMasterPubkeys.isEmpty) {
    return [];
  }

  final metadataExpiration =
      ref.read(envProvider.notifier).get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES);

  // Load all user preview data upfront and cache in a map
  final userPreviewDataFutures = receiverMasterPubkeys.map(
    (pubkey) => ref
        .read(
          userPreviewDataProvider(
            pubkey,
            expirationDuration: Duration(minutes: metadataExpiration),
          ).future,
        )
        .then((data) => MapEntry(pubkey, data)),
  );

  final userPreviewDataEntries = await Future.wait(userPreviewDataFutures);

  final userPreviewDataMap = Map.fromEntries(
    userPreviewDataEntries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, entry.value!)),
  );

  // Build results using cached user preview data
  final result = messages.map((message) {
    if (messagePubkeyMap[message] case final receiverMasterPubkey?) {
      if (userPreviewDataMap[receiverMasterPubkey] case final userPreviewData?) {
        return ChatSearchResultItem(
          masterPubkey: userPreviewData.masterPubkey,
          lastMessageContent: message.data.content,
        );
      }
    }
  });
  return result.nonNulls.toList();
}
