// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/chat/providers/conversations_provider.r.dart';
import 'package:ion/app/features/user_archive/providers/user_archive_provider.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toggle_archive_conversation_provider.r.g.dart';

@riverpod
class ToggleArchivedConversations extends _$ToggleArchivedConversations {
  @override
  FutureOr<void> build() async {}

  Future<void> toggleConversations(List<String> conversationIds) async {
    final currentlyArchivedConversations =
        ref.read(archivedConversationsProvider).valueOrNull?.map((e) => e.conversationId).toSet() ??
            <String>{};

    final conversationsToBeArchived = <String>[];
    final allArchivedConversations = <String>{...currentlyArchivedConversations};

    for (final conversationId in conversationIds) {
      if (currentlyArchivedConversations.contains(conversationId)) {
        // Unarchive: remove from the set
        allArchivedConversations.remove(conversationId);
      } else {
        // Archive: add to both sets
        conversationsToBeArchived.add(conversationId);
        allArchivedConversations.add(conversationId);
      }
    }

    final userArchiveService = await ref.read(userArchiveServiceProvider.future);
    await userArchiveService.sendUserArchiveEvent(allArchivedConversations.toList());

    final localNotificationsService = await ref.read(localNotificationsServiceProvider.future);
    unawaited(localNotificationsService.cancelByGroupKeys(conversationsToBeArchived));
  }
}
