// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/optimistic_ui/model/optimistic_message_reactions.f.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/optimistic_ui/reaction_sync_strategy_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/optimistic_ui/toggle_reaction_intent.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_reactions_provider.r.g.dart';

@riverpod
Future<List<OptimisticMessageReactions>> loadInitialMessageReactions(
  Ref ref,
  EventReference eventReference,
) async {
  final conversationMessageReactionDao = ref.watch(conversationMessageReactionDaoProvider);

  final reactionGroups =
      await conversationMessageReactionDao.messageReactions(eventReference).first;

  return [
    OptimisticMessageReactions(
      eventReference: eventReference,
      reactions: reactionGroups,
    ),
  ];
}

@riverpod
OptimisticOperationManager<OptimisticMessageReactions> messageReactionManager(Ref ref) {
  final strategy = ref.watch(reactionSyncStrategyProvider);
  final localEnabled = true;
//  ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);

  final manager = OptimisticOperationManager<OptimisticMessageReactions>(
    syncCallback: strategy.send,
    enableLocal: localEnabled,
    onError: (_, __) async => true,
  );

  ref.onDispose(manager.dispose);

  return manager;
}

@riverpod
OptimisticService<OptimisticMessageReactions> messageReactionService(Ref ref) {
  final manager = ref.watch(messageReactionManagerProvider);
  final service = OptimisticService<OptimisticMessageReactions>(manager: manager);

  return service;
}

@riverpod
Stream<OptimisticMessageReactions?> messageReactionWatch(Ref ref, EventReference eventReference) {
  final service = ref.watch(messageReactionServiceProvider)
    ..initialize(loadInitialMessageReactions(ref, eventReference));

  return service.watch(eventReference.toString());
}

@riverpod
class ToggleReactionNotifier extends _$ToggleReactionNotifier {
  @override
  void build() {}

  Future<void> toggle({
    required String emoji,
    required EventReference eventReference,
    required String currentUserMasterPubkey,
  }) async {
    final service = ref.read(messageReactionServiceProvider);

    var current = ref.read(messageReactionWatchProvider(eventReference)).valueOrNull;

    current ??= OptimisticMessageReactions(reactions: [], eventReference: eventReference);

    await service.dispatch(
        ToggleReactionIntent(emoji: emoji, currentMasterPubkey: currentUserMasterPubkey), current);
  }
}
