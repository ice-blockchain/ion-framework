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

final chatSearchCacheProvider = StateProvider<Map<String, List<ChatSearchResultItem>>>((ref) {
  return {};
});

@riverpod
Future<List<ChatSearchResultItem>?> chatMessagesSearch(
  Ref ref,
  String query,
) async {
  final stopwatch = Stopwatch()..start();
  print("QWERTY [SEARCH START] query: $query");

  if (query.isEmpty) return null;

  final cachedResults = ref.watch(chatSearchCacheProvider);
  if (cachedResults.containsKey(query)) {
    print("QWERTY [CACHE HIT] took: ${stopwatch.elapsedMilliseconds}ms");
    return cachedResults[query];
  }
  print("QWERTY [CACHE MISS] took: ${stopwatch.elapsedMilliseconds}ms");

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserMasterPubkey == null) return null;

  final caseInsensitiveQuery = query.toLowerCase();
  print("QWERTY [AFTER SETUP] took: ${stopwatch.elapsedMilliseconds}ms");

  final eventMessageDao = ref.watch(eventMessageDaoProvider);

  final dbStopwatch = Stopwatch()..start();
  final searchResults = await eventMessageDao.search(caseInsensitiveQuery);
  dbStopwatch.stop();
  print("QWERTY [DB SEARCH] found ${searchResults.length} messages, took: ${dbStopwatch.elapsedMilliseconds}ms, total: ${stopwatch.elapsedMilliseconds}ms");

  final entityStopwatch = Stopwatch()..start();
  final entities = searchResults.map(ReplaceablePrivateDirectMessageEntity.fromEventMessage);

  // Database already returns results sorted by createdAt DESC, no need to sort again
  final messages = entities.toList();
  entityStopwatch.stop();
  print("QWERTY [ENTITY MAPPING] ${messages.length} messages, took: ${entityStopwatch.elapsedMilliseconds}ms, total: ${stopwatch.elapsedMilliseconds}ms");

  // Extract unique receiver pubkeys and filter out nulls early
  final pubkeyStopwatch = Stopwatch()..start();
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
  pubkeyStopwatch.stop();
  print("QWERTY [PUBKEY EXTRACTION] ${receiverMasterPubkeys.length} unique pubkeys, took: ${pubkeyStopwatch.elapsedMilliseconds}ms, total: ${stopwatch.elapsedMilliseconds}ms");

  if (receiverMasterPubkeys.isEmpty) {
    ref.read(chatSearchCacheProvider.notifier).update((state) => {...state, query: []});
    print("QWERTY [EMPTY RESULT] took: ${stopwatch.elapsedMilliseconds}ms");
    return [];
  }

  final metadataExpiration =
      ref.read(envProvider.notifier).get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES);

  // Load all user preview data upfront and cache in a map
  final userDataStopwatch = Stopwatch()..start();
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
  userDataStopwatch.stop();
  print("QWERTY [USER DATA LOAD] ${receiverMasterPubkeys.length} users, took: ${userDataStopwatch.elapsedMilliseconds}ms, total: ${stopwatch.elapsedMilliseconds}ms");

  final userPreviewDataMap = {
    for (final entry in userPreviewDataEntries)
      if (entry.value != null) entry.key: entry.value!,
  };
  print("QWERTY [USER DATA MAP] ${userPreviewDataMap.length} valid users, total: ${stopwatch.elapsedMilliseconds}ms");

  // Build results using cached user preview data
  final resultStopwatch = Stopwatch()..start();
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
  resultStopwatch.stop();
  print("QWERTY [RESULT BUILD] ${result.length} results, took: ${resultStopwatch.elapsedMilliseconds}ms, total: ${stopwatch.elapsedMilliseconds}ms");

  ref.read(chatSearchCacheProvider.notifier).update((state) => {...state, query: result});
  stopwatch.stop();
  print("QWERTY [SEARCH COMPLETE] ${result.length} results, total time: ${stopwatch.elapsedMilliseconds}ms");
  return result;
}
