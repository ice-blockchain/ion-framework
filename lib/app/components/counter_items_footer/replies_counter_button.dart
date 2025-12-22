// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/counter_items_footer/text_action_button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/providers/can_reply_notifier.r.dart';
import 'package:ion/app/features/feed/providers/counters/replied_events_provider.r.dart';
import 'package:ion/app/features/feed/providers/counters/replies_count_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/who_can_reply_info_modal/who_can_reply_info_modal.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class RepliesCounterButton extends HookConsumerWidget {
  const RepliesCounterButton({
    required this.eventReference,
    this.color,
    this.padding,
    this.onTap,
    super.key,
  });

  final EventReference eventReference;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repliesCount = ref.watch(repliesCountProvider(eventReference)).valueOrNull ?? 0;
    final isReplied = ref.watch(isRepliedProvider(eventReference));
    final canReply = ref.watch(canReplyProvider(eventReference)).valueOrNull ?? true;
    final isLoading = useRef(false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (onTap case final onTap?) {
          onTap();
          return;
        }
        if (isLoading.value) {
          return;
        }
        try {
          isLoading.value = true;
          await _onTap(ref);
        } finally {
          isLoading.value = false;
        }
      },
      child: Container(
        constraints: BoxConstraints(minWidth: 50.0.s),
        padding: padding,
        alignment: AlignmentDirectional.centerStart,
        child: TextActionButton(
          icon: Assets.svg.iconBlockComment.icon(
            size: 16.0.s,
            color: color ?? context.theme.appColors.onTertiaryBackground,
          ),
          textColor: color ?? context.theme.appColors.onTertiaryBackground,
          activeIcon: Assets.svg.iconBlockCommenton.icon(
            size: 16.0.s,
            color: context.theme.appColors.primaryAccent,
          ),
          activeTextColor: context.theme.appColors.primaryAccent,
          disabledIcon: Assets.svg.iconBlockComment.icon(
            size: 16.0.s,
            color: context.theme.appColors.tertiaryText,
          ),
          disabledTextColor: context.theme.appColors.tertiaryText,
          value: formatDoubleCompact(repliesCount),
          state: switch ((canReply, isReplied)) {
            (false, _) => TextActionButtonState.disabled,
            (true, true) => TextActionButtonState.active,
            (true, false) => TextActionButtonState.idle,
          },
        ),
      ),
    );
  }

  Future<void> _onTap(WidgetRef ref) async {
    final entity = await ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
    final canReply = await ref.read(canReplyProvider(eventReference).future) ?? true;

    if (!ref.context.mounted || entity == null) return;

    if (canReply) {
      if (entity is ArticleEntity) {
        await ArticleRepliesRoute(eventReference: eventReference.encode()).push<void>(ref.context);
      } else {
        await CreateReplyRoute(parentEvent: eventReference.encode()).push<void>(ref.context);
      }
      await HapticFeedback.lightImpact();
    } else {
      await showSimpleBottomSheet<void>(
        context: ref.context,
        child: WhoCanReplyInfoModal(
          eventReference: eventReference,
        ),
      );
    }
  }
}
