// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/polls/providers/poll_draft_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class PollAddAnswerButton extends ConsumerWidget {
  const PollAddAnswerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollDraft = ref.watch(pollDraftNotifierProvider);

    if (pollDraft.answers.length == 4) {
      return SizedBox(height: 10.0.s);
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Button(
        disabled: pollDraft.isVoted,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsetsDirectional.only(top: 8.0.s, bottom: 10.0.s),
          ),
          minimumSize: WidgetStatePropertyAll<Size>(Size(0, 28.0.s)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        type: ButtonType.secondary,
        label: Text(
          context.i18n.poll_add_answer_button_title,
          style: context.theme.appTextThemes.caption.copyWith(
            color: context.theme.appColors.primaryAccent,
            fontSize: 12.0.s,
          ),
        ),
        backgroundColor: context.theme.appColors.secondaryBackground,
        borderColor: context.theme.appColors.secondaryBackground,
        leadingIcon: Assets.svg.iconPostAddanswer.icon(
          color: context.theme.appColors.primaryAccent,
          size: 16.0.s,
        ),
        leadingIconOffset: 4.0.s,
        onPressed: () {
          ref.read(pollDraftNotifierProvider.notifier).addAnswer();
        },
      ),
    );
  }
}
