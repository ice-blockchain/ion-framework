// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/search/model/chat_search_result_item.f.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_privacy_cache_expiration_duration_provider.r.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_messages_search_provider.r.g.dart';

typedef _ReceiverPubkeysExtraction = ({
  Map<ReplaceablePrivateDirectMessageEntity, String> messagePubkeyMap,
  Set<String> receiverPubkeys,
});

@riverpod
Future<List<ChatSearchResultItem>?> chatMessagesSearch(Ref ref, String query) async {
  if (query.isEmpty) return null;

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserMasterPubkey == null) return null;

  final messages = await _searchMessages(ref, query);
  final (:messagePubkeyMap, :receiverPubkeys) =
      _extractReceiverPubkeys(messages, currentUserMasterPubkey);

  if (receiverPubkeys.isEmpty) {
    return [];
  }

  final expirationDuration = ref.watch(chatPrivacyCacheExpirationDurationProvider);

  final userPreviewDataMap = await _loadUserPreviewData(ref, receiverPubkeys, expirationDuration);

  return _buildSearchResults(messages, messagePubkeyMap, userPreviewDataMap);
}

String? _getReceiverPubkey(
  ReplaceablePrivateDirectMessageEntity message,
  String currentUserMasterPubkey,
) {
  return message.allPubkeys.firstWhereOrNull((key) => key != currentUserMasterPubkey);
}

Future<Iterable<ReplaceablePrivateDirectMessageEntity>> _searchMessages(
  Ref ref,
  String query,
) async {
  final caseInsensitiveQuery = query.toLowerCase();
  final eventMessageDao = ref.watch(eventMessageDaoProvider);
  final searchResults = await eventMessageDao.search(caseInsensitiveQuery);
  return searchResults.map(ReplaceablePrivateDirectMessageEntity.fromEventMessage);
}

_ReceiverPubkeysExtraction _extractReceiverPubkeys(
  Iterable<ReplaceablePrivateDirectMessageEntity> messages,
  String currentUserMasterPubkey,
) {
  final messagePubkeyMap = <ReplaceablePrivateDirectMessageEntity, String>{
    for (final message in messages)
      if (_getReceiverPubkey(message, currentUserMasterPubkey) case final receiverPubkey?)
        message: receiverPubkey,
  };
  final receiverPubkeys = messagePubkeyMap.values.toSet();
  return (messagePubkeyMap: messagePubkeyMap, receiverPubkeys: receiverPubkeys);
}

Future<Map<String, UserPreviewEntity>> _loadUserPreviewData(
  Ref ref,
  Set<String> receiverMasterPubkeys,
  Duration expirationDuration,
) async {
  final userPreviewDataFutures = receiverMasterPubkeys.map(
    (pubkey) => ref
        .read(
          userPreviewDataProvider(
            pubkey,
            expirationDuration: expirationDuration,
          ).future,
        )
        .then((data) => MapEntry(pubkey, data)),
  );

  final userPreviewDataEntries = await Future.wait(userPreviewDataFutures);

  return Map.fromEntries(
    userPreviewDataEntries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, entry.value!)),
  );
}

List<ChatSearchResultItem> _buildSearchResults(
  Iterable<ReplaceablePrivateDirectMessageEntity> messages,
  Map<ReplaceablePrivateDirectMessageEntity, String> messagePubkeyMap,
  Map<String, UserPreviewEntity> userPreviewDataMap,
) {
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
