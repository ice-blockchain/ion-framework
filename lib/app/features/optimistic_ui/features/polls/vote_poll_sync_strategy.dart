// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/models/poll_vote_state.f.dart';

class VotePollSyncStrategy implements SyncStrategy<PollVoteState> {
  VotePollSyncStrategy({
    required this.sendVote,
  });

  final Future<PollVoteState> Function(
    PollData pollData,
    int userVotedOptionIndex,
    EventReference eventReference,
    List<int> voteCounts,
  ) sendVote;

  @override
  Future<PollVoteState> send(
    PollVoteState prev,
    PollVoteState optimistic,
  ) async {
    await sendVote(
      optimistic.pollData,
      optimistic.userVotedOptionIndex,
      optimistic.eventReference,
      optimistic.voteCounts,
    );

    return optimistic;
  }
}
