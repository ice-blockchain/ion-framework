// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/model/poll_vote_state.f.dart';

/// Sync strategy for poll votes.
class PollVoteSyncStrategy implements SyncStrategy<PollVoteState> {
  PollVoteSyncStrategy({
    required this.sendVote,
  });

  final Future<bool> Function(EventReference eventReference, int optionIndex) sendVote;

  @override
  Future<PollVoteState> send(PollVoteState previous, PollVoteState optimistic) async {
    final optionIndex = optimistic.userVotedOptionIndex;
    if (optionIndex == null) return optimistic;

    // Delegate to existing vote sending logic; assume it updates caches as needed.
    await sendVote(optimistic.eventReference, optionIndex);
    return optimistic;
  }
}
