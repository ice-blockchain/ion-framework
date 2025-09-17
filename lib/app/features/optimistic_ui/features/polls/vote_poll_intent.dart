// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/models/poll_vote_state.f.dart';

class VotePollIntent implements OptimisticIntent<PollVoteState> {
  VotePollIntent(this.userVotedOptionIndex);

  final int userVotedOptionIndex;

  @override
  PollVoteState optimistic(PollVoteState current) {
    return current.copyWith(
      userVotedOptionIndex: userVotedOptionIndex,
      voteCounts: current.voteCounts
          .map(
            (e) => e + (e == userVotedOptionIndex ? 1 : 0),
          )
          .toList(),
    );
  }

  @override
  Future<PollVoteState> sync(PollVoteState prev, PollVoteState next) async => next;
}
