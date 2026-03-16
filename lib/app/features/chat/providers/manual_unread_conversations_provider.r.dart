// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'manual_unread_conversations_provider.r.g.dart';

const _manualUnreadConversationsKey = 'chat.manual_unread_conversations';

@riverpod
class ManualUnreadConversations extends _$ManualUnreadConversations {
  @override
  Set<String> build() {
    final preferences = ref.read(currentUserPreferencesServiceProvider);
    final stored = preferences?.getValue<List<String>>(_manualUnreadConversationsKey) ?? [];
    return stored.toSet();
  }

  Future<void> _persist() async {
    final preferences = ref.read(currentUserPreferencesServiceProvider);
    if (preferences == null) {
      return;
    }

    await preferences.setValue<List<String>>(
      _manualUnreadConversationsKey,
      state.toList(),
    );
  }

  void markUnread(String conversationId) {
    if (state.contains(conversationId)) {
      return;
    }
    state = {...state, conversationId};
    unawaited(_persist());
  }

  void clearUnread(String conversationId) {
    if (!state.contains(conversationId)) {
      return;
    }
    final updated = Set<String>.from(state)..remove(conversationId);
    state = updated;
    unawaited(_persist());
  }

  void clearUnreadForConversations(Iterable<String> conversationIds) {
    if (conversationIds.isEmpty) {
      return;
    }

    final updated = Set<String>.from(state)..removeAll(conversationIds);
    if (updated.length == state.length) {
      return;
    }

    state = updated;
    unawaited(_persist());
  }
}
