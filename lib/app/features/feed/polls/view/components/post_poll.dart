// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/polls/models/poll_data.f.dart';
import 'package:ion/app/features/feed/polls/providers/poll_results_provider.r.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_vote.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_vote_result.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/optimistic_ui/features/polls/vote_poll_provider.r.dart';

class PostPoll extends ConsumerWidget {
  const PostPoll({
    required this.pollData,
    required this.postReference,
    this.accentTheme = false,
    super.key,
  });

  final bool accentTheme;
  final PollData pollData;
  final EventReference postReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteCounts = ref.watch(pollVoteCountsProvider(postReference, pollData));
    final userVotedOptionIndex = ref.watch(userVotedOptionIndexProvider(postReference));
    final hasVoted = ref.watch(hasUserVotedProvider(postReference));
    final optimisticHasVoted = ref
        .watch(
          pollVoteWatchProvider(pollData.ttl.toString()),
        )
        .valueOrNull
        ?.userVotedOptionIndex;

    final isOwnedByCurrentUser = ref.watch(isCurrentUserSelectorProvider(postReference.masterPubkey));
    final userHasVoted = userVotedOptionIndex != null || hasVoted || optimisticHasVoted != null;
    final shouldShowResults = pollData.isClosed || userHasVoted || isOwnedByCurrentUser;

    if (shouldShowResults) {
      return PollVoteResult(
        pollData: pollData,
        voteCounts: voteCounts,
        accentTheme: accentTheme,
        userVotedOptionIndex: userVotedOptionIndex,
      );
    } else {
      return PollVote(
        pollData: pollData,
        accentTheme: accentTheme,
        selectedOptionIndex: userVotedOptionIndex,
        onVote: (optionIndex) async {
          await ref.read(togglePollVoteNotifierProvider.notifier).vote(
                postReference,
                pollData,
                optionIndex,
                voteCounts,
              );
        },
      );
    }
  }
}
