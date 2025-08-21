// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/model/poll_vote_state.f.dart';

/// Intent to optimistically set user's vote and increment the selected option count.
final class TogglePollVoteIntent implements OptimisticIntent<PollVoteState> {
  TogglePollVoteIntent(this.optionIndex);

  final int optionIndex;

  @override
  PollVoteState optimistic(PollVoteState current) {
    final counts = List<int>.from(current.voteCounts);
    // If the user had a previous vote, decrement it first.
    if (current.userVotedOptionIndex != null &&
        current.userVotedOptionIndex! >= 0 &&
        current.userVotedOptionIndex! < counts.length) {
      counts[current.userVotedOptionIndex!] =
          (counts[current.userVotedOptionIndex!] - 1).clamp(0, 1 << 31);
    }

    if (optionIndex >= 0 && optionIndex < counts.length) {
      counts[optionIndex] = counts[optionIndex] + 1;
    }

    return current.copyWith(
      voteCounts: counts,
      userVotedOptionIndex: optionIndex,
    );
  }

  @override
  Future<PollVoteState> sync(PollVoteState prev, PollVoteState next) =>
      throw UnimplementedError('Sync is handled by strategy');
}
