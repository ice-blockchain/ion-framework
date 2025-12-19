// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/participants_keys.f.dart';
import 'package:ion/app/features/chat/providers/exist_one_to_one_chat_conversation_id_provider.r.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/features/user_mute/providers/user_mute_provider.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:ion/app/services/uuid/generate_conversation_id.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'muted_conversations_provider.r.g.dart';

@riverpod
Future<List<String>> mutedConversations(Ref ref) async {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  // As for now only one-to-one conversations can be muted, we need to clarify
  // if same will be used for public channels or group chats in future or we
  // will have to use muted sets 3007
  final mutedUsers = ref.watch(mutedUsersProvider).valueOrNull ?? [];

  final mutedConversations = mutedUsers
      .map(
        (masterPubkey) => generateConversationId(
          conversationType: ConversationType.oneToOne,
          participantsMasterPubkeys: [masterPubkey, currentUserMasterPubkey],
        ),
      )
      .toList();

  return mutedConversations;
}

@riverpod
Future<MuteConversationService> muteConversationService(Ref ref) async {
  return MuteConversationService(
    userMuteService: await ref.watch(userMuteServiceProvider.future),
    currentUserMasterPubkey: ref.watch(currentPubkeySelectorProvider),
    mutedUsersMasterPubkeys: await ref.watch(mutedUsersProvider.future),
    localNotificationsService: await ref.watch(localNotificationsServiceProvider.future),
    conversationIdProvider: (ParticipantKeys participants) =>
        ref.read(existOneToOneChatConversationIdProvider(participants).future),
  );
}

class MuteConversationService {
  MuteConversationService({
    required this.userMuteService,
    required this.conversationIdProvider,
    required this.mutedUsersMasterPubkeys,
    required this.currentUserMasterPubkey,
    required this.localNotificationsService,
  });

  final String? currentUserMasterPubkey;
  final UserMuteService userMuteService;
  final List<String> mutedUsersMasterPubkeys;
  final LocalNotificationsService localNotificationsService;
  final Future<String> Function(ParticipantKeys participants) conversationIdProvider;

  Future<void> toggleMutedConversation(String masterPubkey) async {
    final mutedUsers = List<String>.from(mutedUsersMasterPubkeys);

    final isCurrentlyMuted = mutedUsers.contains(masterPubkey);

    if (isCurrentlyMuted) {
      mutedUsers.remove(masterPubkey);
    } else {
      mutedUsers.add(masterPubkey);
      await cleanConversationNotifications(masterPubkey);
    }

    await userMuteService.sendUserMuteEvent(mutedUsers);
  }

  Future<void> cleanConversationNotifications(String masterPubkey) async {
    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final participantsMasterPubkeys =
        ParticipantKeys(keys: [masterPubkey, currentUserMasterPubkey!].sorted());

    final conversationId = await conversationIdProvider(participantsMasterPubkeys);

    unawaited(localNotificationsService.cancelByGroupKey(conversationId));
  }
}
