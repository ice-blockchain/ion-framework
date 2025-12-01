// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/polls/providers/poll_draft_provider.r.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_add_answer_button.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_answers_list_view.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_close_button.dart';
import 'package:ion/app/features/feed/polls/view/components/poll_length_button.dart';
import 'package:ion/app/features/feed/views/pages/poll_length_time_modal/poll_length_time_modal.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';

class Poll extends ConsumerWidget {
  const Poll({
    super.key,
    this.onRemove,
  });

  final VoidCallback? onRemove;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final draftPoll = ref.watch(pollDraftNotifierProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.theme.appColors.onPrimaryAccent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.theme.appColors.onTertiaryFill,
                ),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: 10.0.s,
                  start: 10.0.s,
                  end: 10.0.s,
                ),
                child: const Column(
                  children: [
                    PollAnswersListView(),
                    PollAddAnswerButton(),
                  ],
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: draftPoll.isVoted
                  ? null
                  : () => _handlePollLengthTap(
                        ref,
                        draftPoll.lengthDays,
                        draftPoll.lengthHours,
                      ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PollLengthButton(
                    onPollLengthPress: () => draftPoll.isVoted
                        ? {}
                        : _handlePollLengthTap(
                            ref,
                            draftPoll.lengthDays,
                            draftPoll.lengthHours,
                          ),
                  ),
                  Text(
                    getFormattedPollLength(context, draftPoll.lengthDays, draftPoll.lengthHours),
                    style: context.theme.appTextThemes.caption.copyWith(
                      color: context.theme.appColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (onRemove != null && !draftPoll.isVoted)
          PollCloseButton(
            onClosePress: onRemove!,
          ),
      ],
    );
  }

  void _handlePollLengthTap(WidgetRef ref, int lengthDays, int lengthHours) {
    final notifier = ref.read(pollDraftNotifierProvider.notifier);

    _showPollLengthTimeModal(
      ref.context,
      lengthDays,
      lengthHours,
      (newDay, newHour) {
        notifier
          ..setLengthDays(newDay)
          ..setLengthHours(newHour);
      },
    );
  }

  Future<void> _showPollLengthTimeModal(
    BuildContext context,
    int selectedDay,
    int selectedHour,
    void Function(int, int) onApply,
  ) async {
    return showSimpleBottomSheet<void>(
      context: context,
      child: PollLengthTimeModal(
        selectedDay: selectedDay,
        selectedHour: selectedHour,
        onApply: onApply,
      ),
    );
  }
}

String getFormattedPollLength(BuildContext context, int days, int hours) {
  if (days > 0 && hours > 0) {
    return '$days ${Intl.plural(
      days,
      one: context.i18n.day(1),
      other: context.i18n.day(days),
    )} $hours ${Intl.plural(
      hours,
      one: context.i18n.hour(1),
      other: context.i18n.hour(hours),
    )}';
  } else if (days > 0) {
    return '$days ${Intl.plural(
      days,
      one: context.i18n.day(1),
      other: context.i18n.day(days),
    )}';
  } else if (hours > 0) {
    return '$hours ${Intl.plural(
      hours,
      one: context.i18n.hour(1),
      other: context.i18n.hour(hours),
    )}';
  }

  return '';
}
