// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/polls/providers/poll_results_provider.r.dart';
import 'package:ion/app/features/feed/polls/providers/poll_vote_notifier.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/models/poll_vote_state.f.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/vote_poll_intent.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/vote_poll_sync_strategy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vote_poll_provider.r.g.dart';

@riverpod
OptimisticOperationManager<PollVoteState> pollVoteManager(Ref ref) {
  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);
  final strategy = VotePollSyncStrategy(
    sendVote: (pollData, optionIdx, eventRef, voteCounts) async {
      unawaited(
        ref.read(pollVoteNotifierProvider.notifier).vote(
              eventRef,
              optionIdx.toString(),
            ),
      );

      ref.read(pollVoteCountsProvider(eventRef, pollData).notifier).addOne(
            optionIdx,
          );

      return PollVoteState(
        pollData: pollData,
        voteCounts: voteCounts,
        userVotedOptionIndex: optionIdx,
        eventReference: eventRef,
      );
    },
  );

  final manager = OptimisticOperationManager<PollVoteState>(
    syncCallback: strategy.send,
    onError: (_, __) async => true,
    enableLocal: localEnabled,
    clearOnSuccessfulSync: true,
  );

  ref.onDispose(manager.dispose);
  return manager;
}

@riverpod
OptimisticService<PollVoteState> pollVoteService(Ref ref) {
  final manager = ref.watch(pollVoteManagerProvider);
  final service = OptimisticService<PollVoteState>(manager: manager)..initialize([]);
  return service;
}

@riverpod
Stream<PollVoteState?> pollVoteWatch(Ref ref, String ttlOfVote) {
  final service = ref.watch(pollVoteServiceProvider);
  return service.watch(ttlOfVote);
}

@riverpod
class TogglePollVoteNotifier extends _$TogglePollVoteNotifier {
  @override
  void build() {}

  Future<void> vote(
    EventReference eventReference,
    PollData pollData,
    int optionIndex,
    List<int> voteCounts,
  ) async {
    final key = eventReference.toString();

    try {
      final service = ref.read(pollVoteServiceProvider);

      final id = key;
      var current = ref.read(pollVoteWatchProvider(id)).valueOrNull;

      current ??= PollVoteState(
        eventReference: eventReference,
        voteCounts: voteCounts,
        userVotedOptionIndex: optionIndex,
        pollData: pollData,
      );

      await service.dispatch(VotePollIntent(optionIndex), current);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {}
  }
}
