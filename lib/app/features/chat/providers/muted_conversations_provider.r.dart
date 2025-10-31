// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/exist_chat_conversation_id_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/mute_set.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:ion/app/services/uuid/generate_conversation_id.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'muted_conversations_provider.r.g.dart';

@riverpod
class MutedConversations extends _$MutedConversations {
  @override
  FutureOr<MuteSetEntity?> build() async {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final requestMessage = RequestMessage()
      ..addFilter(
        RequestFilter(
          kinds: const [MuteSetEntity.kind],
          authors: [currentUserMasterPubkey],
          tags: {
            '#d': [MuteSetType.chatConversations.dTagName],
          },
        ),
      );

    final mutedConversationsEntity =
        await ref.read(ionConnectNotifierProvider.notifier).requestEntity<MuteSetEntity>(
              requestMessage,
            );

    return mutedConversationsEntity;
  }

  Future<void> toggleMutedMasterPubkey(String masterPubkey) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final existingMutedMasterPubkeys = state.value?.data.masterPubkeys ?? [];

      final shouldBeMuted = !existingMutedMasterPubkeys.contains(masterPubkey);

      final List<String> newMutedMasterPubkeys;
      if (shouldBeMuted) {
        newMutedMasterPubkeys = [...existingMutedMasterPubkeys, masterPubkey];
        unawaited(_cleanConversationNotifications(masterPubkey));
      } else {
        newMutedMasterPubkeys = existingMutedMasterPubkeys.where((p) => p != masterPubkey).toList();
      }

      final MuteSetData muteSetData;
      if (state.value != null) {
        muteSetData = state.value!.data.copyWith(masterPubkeys: newMutedMasterPubkeys);
      } else {
        muteSetData = MuteSetData(
          type: MuteSetType.chatConversations,
          masterPubkeys: newMutedMasterPubkeys,
        );
      }

      final muteSetEntity =
          await ref.read(ionConnectNotifierProvider.notifier).sendEntityData<MuteSetEntity>(
                muteSetData,
              );

      return muteSetEntity;
    });
  }

  Future<void> _cleanConversationNotifications(
    String masterPubkey,
  ) async {
    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentUserMasterPubkey == null) {
      return;
    }

    final participantsMasterPubkeys = [masterPubkey, currentUserMasterPubkey];
    final conversationId = await ref.read(
          existChatConversationIdProvider(participantsMasterPubkeys).future,
        ) ??
        generateConversationId(
          conversationType: ConversationType.direct,
          receiverMasterPubkeys: [masterPubkey, currentUserMasterPubkey],
        );
    final localNotificationsService = await ref.read(localNotificationsServiceProvider.future);
    unawaited(localNotificationsService.cancelByGroupKey(conversationId));
  }
}

@riverpod
Future<List<String>> mutedConversationIds(Ref ref) async {
  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final mutedConversations = await ref.watch(mutedConversationsProvider.future);
  final mutedCommunityIds = mutedConversations?.data.communityIds ?? [];

  final mutedReceiverPubkeys = mutedConversations?.data.masterPubkeys ?? [];

  final mutedOneToOneConversationIds = [
    ...mutedReceiverPubkeys.map(
      (masterPubkey) => generateConversationId(
        conversationType: ConversationType.direct,
        receiverMasterPubkeys: [masterPubkey, currentUserMasterPubkey],
      ),
    ),
  ];

  return [
    ...mutedOneToOneConversationIds,
    ...mutedCommunityIds,
  ];
}
