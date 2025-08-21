// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
// import 'package:ion/app/features/feed/polls/models/poll_vote.f.dart';
import 'package:ion/app/features/feed/polls/providers/poll_results_provider.r.dart';
import 'package:ion/app/features/feed/polls/providers/poll_vote_notifier.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/model/poll_vote_state.f.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/poll_vote_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/toggle_poll_vote_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'poll_vote_provider.r.g.dart';

@riverpod
List<PollVoteState> loadInitialPollVotesFromCache(Ref ref) => [];

@riverpod
OptimisticOperationManager<PollVoteState> pollVoteManager(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);
  final strategy = PollVoteSyncStrategy(
    sendVote: (eventRef, optionIdx) async {
      return ref.read(pollVoteNotifierProvider.notifier).vote(eventRef, optionIdx.toString());
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
  keepAliveWhenAuthenticated(ref);
  final manager = ref.watch(pollVoteManagerProvider);
  final initial = ref.watch(loadInitialPollVotesFromCacheProvider);
  final service = OptimisticService<PollVoteState>(manager: manager)..initialize(initial);
  return service;
}

@riverpod
Stream<PollVoteState?> pollVoteWatch(Ref ref, String id) {
  keepAliveWhenAuthenticated(ref);
  final service = ref.watch(pollVoteServiceProvider);
  final manager = ref.watch(pollVoteManagerProvider);

  var last = manager.snapshot.firstWhereOrNull((e) => e.optimisticId == id);
  return service.watch(id).map((value) {
    if (value != null) {
      last = value;
      return value;
    }
    return last;
  });
}

@riverpod
class TogglePollVoteNotifier extends _$TogglePollVoteNotifier {
  final _processing = <String>{};

  @override
  void build() {
    keepAliveWhenAuthenticated(ref);
  }

  Future<void> vote(EventReference eventReference, PollData pollData, int optionIndex) async {
    final key = eventReference.toString();
    if (_processing.contains(key)) return;
    _processing.add(key);

    try {
      final service = ref.read(pollVoteServiceProvider);

      final id = key;
      var current = ref.read(pollVoteWatchProvider(id)).valueOrNull;

      current ??= PollVoteState(
        eventReference: eventReference,
        voteCounts: ref.read(pollVoteCountsProvider(eventReference, pollData)),
        userVotedOptionIndex: ref.read(userVotedOptionIndexProvider(eventReference)),
      );

      await service.dispatch(TogglePollVoteIntent(optionIndex), current);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } finally {
      _processing.remove(key);
    }
  }
}
