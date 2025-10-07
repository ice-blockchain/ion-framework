// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/search/model/chat_search_result_item.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_local_user_search_provider.r.g.dart';

@riverpod
Future<List<ChatSearchResultItem>?> chatLocalUserSearch(Ref ref, String query) async {
  if (query.isEmpty) return null;

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserMasterPubkey == null) return null;

  final caseInsensitiveQuery = query.toLowerCase();

  final lastConversationMessages = ref
          .watch(conversationsProvider)
          .value
          ?.map((conversation) => conversation.latestMessage)
          .nonNulls
          .toList() ??
      [];

  final lastConversationEntities = lastConversationMessages
      .map(ReplaceablePrivateDirectMessageEntity.fromEventMessage)
      .toList()
    ..sortBy((message) => message.createdAt.toDateTime);

  final result = <ChatSearchResultItem>[];

  for (final message in lastConversationEntities.reversed) {
    final receiverMasterPubkey = message.allPubkeys.firstWhereOrNull(
      (key) => key != currentUserMasterPubkey,
    );

    if (receiverMasterPubkey == null) continue;

    final metadataExpiration =
        ref.read(envProvider.notifier).get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES);

    final userMetadata = await ref.watch(
      userMetadataProvider(
        receiverMasterPubkey,
        expirationDuration: Duration(minutes: metadataExpiration),
      ).future,
    );

    if (userMetadata == null) continue;

    final nameMatches = userMetadata.data.name.toLowerCase().contains(caseInsensitiveQuery);
    final displayNameMatches =
        userMetadata.data.displayName.toLowerCase().contains(caseInsensitiveQuery);
    if (!nameMatches && !displayNameMatches) continue;

    result.add(
      ChatSearchResultItem(
        userMetadata: userMetadata,
        lastMessageContent: message.data.content,
      ),
    );
  }

  return result;
}
