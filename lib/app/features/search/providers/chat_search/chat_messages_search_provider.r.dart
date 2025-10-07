// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
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

  final result = <ChatSearchResultItem>[];

  entities.sortedBy((entity) => entity.createdAt.toDateTime).reversed.forEach((message) async {
    final receiverMasterPubkey = message.allPubkeys.firstWhereOrNull(
      (key) => key != currentUserMasterPubkey,
    );

    if (receiverMasterPubkey == null) return;

    final metadataExpiration =
        ref.read(envProvider.notifier).get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES);

    final userMetadata = ref
        .watch(
          userMetadataProvider(
            receiverMasterPubkey,
            expirationDuration: Duration(minutes: metadataExpiration),
          ),
        )
        .valueOrNull;

    if (userMetadata == null) return;

    result.add(
      ChatSearchResultItem(
        userMetadata: userMetadata,
        lastMessageContent: message.data.content,
      ),
    );
  });

  return result;
}
