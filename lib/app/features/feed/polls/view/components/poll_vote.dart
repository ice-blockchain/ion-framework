// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_vote_item.dart';

class PollVote extends HookConsumerWidget {
  const PollVote({
    required this.pollData,
    required this.onVote,
    this.selectedOptionIndex,
    super.key,
  });

  final PollData pollData;
  final int? selectedOptionIndex;
  final void Function(int optionIndex) onVote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionWidgets = useMemoized(
      () {
        return List.generate(
          pollData.options.length,
          (index) => PollVoteItem(
            key: ValueKey('poll_option_${pollData.options[index]}_$index'),
            text: pollData.options[index],
            isSelected: selectedOptionIndex == index,
            onTap: () => onVote(index),
          ),
        );
      },
      [pollData.options, selectedOptionIndex],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: optionWidgets,
    );
  }
}
