// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_messages_provider.r.g.dart';

@riverpod
class ConversationMessages extends _$ConversationMessages {
  static const int _tailLimit = 100;
  static const int _pageSize = 50;

  StreamSubscription<List<EventMessage>>? _tailSubscription;
  StreamSubscription<List<EventReference>>? _deletedMessagesSubscription;

  @override
  Future<List<EventMessage>> build(
    String conversationId,
  ) async {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    await _tailSubscription?.cancel();
    _tailSubscription = null;
    await _deletedMessagesSubscription?.cancel();
    _deletedMessagesSubscription = null;

    if (currentUserMasterPubkey == null) {
      return [];
    }

    final dao = ref.watch(conversationMessageDaoProvider);

    final initialTail = await dao.watchTail(conversationId, limit: _tailLimit).first;

    _tailSubscription = dao.watchTail(conversationId, limit: _tailLimit).listen(_applyTail);
    _deletedMessagesSubscription =
        dao.watchDeletedMessages(conversationId).listen(_handleDeletedMessages);

    ref.onDispose(() {
      _tailSubscription?.cancel();
      _tailSubscription = null;
      _deletedMessagesSubscription?.cancel();
      _deletedMessagesSubscription = null;
    });

    return initialTail;
  }

  void _applyTail(List<EventMessage> tail) {
    if (tail.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    final currentMessages = state.valueOrNull ?? [];
    final tailIds = tail.map((message) => message.sharedId).toSet();
    final olderMessages = currentMessages.where((message) => !tailIds.contains(message.sharedId));

    final lastMessageItem = tail.firstOrNull;
    if (lastMessageItem != null) {
      final adMessageItem = EventMessage(
        id: 'ad_id_${lastMessageItem.createdAt}',
        content: lastMessageItem.content,
        createdAt: lastMessageItem.createdAt,
        pubkey: 'ad_key_${lastMessageItem.pubkey}',
        kind: lastMessageItem.kind,
        tags: lastMessageItem.tags,
        sig: lastMessageItem.sig,
      );

      tail.insert(0, adMessageItem);
    }

    final merged = [...tail, ...olderMessages];

    state = AsyncData(merged);
  }

  /// Loads more messages (older) and appends them to the state.
  Future<bool> loadMore() async {
    final dao = ref.read(conversationMessageDaoProvider);

    // Current state messages, or empty
    final currentMessages = state.valueOrNull ?? [];

    // If there are no messages, nothing to load more
    if (currentMessages.isEmpty) {
      return false;
    }

    // publishedAt from the last message in the list (oldest in newest-first order)
    final oldestMessage = currentMessages.last;
    final lastMessagePublishedAt = oldestMessage.publishedAt;

    // Fetch older messages before the current oldest
    final olderMessages = await dao.fetchPageBefore(
      conversationId: conversationId,
      beforePublishedAt: lastMessagePublishedAt,
      limit: _pageSize,
    );

    if (olderMessages.isEmpty) {
      return false;
    }

    final knownIds = currentMessages.map((message) => message.id).toSet();
    final uniqueOlder = olderMessages.where((message) => !knownIds.contains(message.id)).toList();

    if (uniqueOlder.isEmpty) {
      return false;
    }

    // Combine keeping newest-first order.
    final combined = [...currentMessages, ...uniqueOlder];

    // Update state
    state = AsyncData(combined);
    return true;
  }

  Future<int?> ensureMessageLoaded(String sharedId) async {
    while (true) {
      final currentMessages = state.valueOrNull ?? [];
      final messageIndex = currentMessages.indexWhere((message) => message.sharedId == sharedId);

      if (messageIndex != -1) {
        return messageIndex;
      }

      final didLoadMore = await loadMore();

      if (!didLoadMore) {
        return null;
      }
    }
  }

  void _handleDeletedMessages(List<EventReference> deletedEventReferences) {
    if (deletedEventReferences.isEmpty) {
      return;
    }
    final currentMessages = state.valueOrNull ?? [];
    if (currentMessages.isEmpty) {
      return;
    }

    final deletedSharedIds = deletedEventReferences
        .whereType<ReplaceableEventReference>()
        .map((ref) => ref.dTag)
        .toSet();

    final updatedMessages =
        currentMessages.where((message) => !deletedSharedIds.contains(message.sharedId)).toList();

    if (updatedMessages.length != currentMessages.length) {
      state = AsyncData(updatedMessages);
    }
  }
}
