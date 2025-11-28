// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/features/feed/polls/providers/poll_draft_provider.r.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_answer_item.dart';

class PollAnswersListView extends ConsumerWidget {
  const PollAnswersListView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftPoll = ref.watch(pollDraftNotifierProvider);

    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (BuildContext context, int index) => SizedBox(height: 10.0.s),
      itemCount: draftPoll.answers.length,
      itemBuilder: (context, index) {
        return PollAnswerItem(
          index: index,
          isLast: index != 0 && index == draftPoll.answers.length - 1,
          readOnly: draftPoll.isVoted,
        );
      },
    );
  }
}
