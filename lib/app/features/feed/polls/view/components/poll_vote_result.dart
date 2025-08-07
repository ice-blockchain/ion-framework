// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/polls/utils/poll_utils.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_vote_result_footer.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_vote_result_item.dart';

class PollVoteResult extends ConsumerWidget {
  const PollVoteResult({
    required this.pollData,
    required this.voteCounts,
    this.accentTheme = false,
    this.userVotedOptionIndex,
    super.key,
  });

  final bool accentTheme;
  final PollData pollData;
  final List<int> voteCounts;
  final int? userVotedOptionIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalVotes = PollUtils.calculateTotalVotes(voteCounts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(
          pollData.options.length,
          (index) {
            return PollResultItem(
              totalVotes: totalVotes,
              accentTheme: accentTheme,
              votes: voteCounts[index],
              text: pollData.options[index],
              isSelected: userVotedOptionIndex == index,
            );
          },
        ),
        SizedBox(height: 6.0.s),
        PollVoteResultFooter(
          pollData: pollData,
          totalVotes: totalVotes,
          accentTheme: accentTheme,
        ),
      ],
    );
  }
}
