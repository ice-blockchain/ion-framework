// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/recent_chats/views/components/recent_chat_tile/recent_chat_actions.dart';

class RecentChatSwipeActions extends HookWidget {
  const RecentChatSwipeActions({
    required this.enabled,
    required this.actions,
    required this.childBuilder,
    super.key,
  });

  final bool enabled;
  final List<RecentChatActionItem> actions;
  final Widget Function(
    BuildContext context,
    VoidCallback closeActions, {
    required bool isActionsOpen,
  }) childBuilder;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 180),
    );
    final swipeOffset = useState<double>(0);
    final animationStartValue = useRef<double>(0);
    final animationEndValue = useRef<double>(0);

    final actionWidth = 76.0.s;
    final totalActionsWidth = actionWidth * actions.length;

    void animateTo(double targetOffset) {
      animationStartValue.value = swipeOffset.value;
      animationEndValue.value = targetOffset;
      animationController.forward(from: 0);
    }

    void closeActions() {
      if (swipeOffset.value == 0) return;
      animateTo(0);
    }

    void openActions() {
      if (!enabled || actions.isEmpty) return;
      animateTo(-totalActionsWidth);
    }

    useEffect(
      () {
        void animationListener() {
          final progress = Curves.easeOut.transform(animationController.value);
          swipeOffset.value = Tween<double>(
            begin: animationStartValue.value,
            end: animationEndValue.value,
          ).transform(progress);

          if (animationController.status == AnimationStatus.completed) {
            swipeOffset.value = animationEndValue.value;
          }
        }

        animationController.addListener(animationListener);
        return () => animationController.removeListener(animationListener);
      },
      [animationController],
    );

    useEffect(
      () {
        if (!enabled || actions.isEmpty) {
          animationController.stop();
          swipeOffset.value = 0;
        } else if (swipeOffset.value.abs() > totalActionsWidth) {
          swipeOffset.value = -totalActionsWidth;
        }
        return null;
      },
      [enabled, actions.length, totalActionsWidth],
    );

    if (actions.isEmpty) {
      return childBuilder(
        context,
        () {},
        isActionsOpen: false,
      );
    }

    final isActionsOpen = swipeOffset.value != 0;
    final revealedWidth = swipeOffset.value.abs();
    final visibleActionsWidth = revealedWidth.clamp(0.0, totalActionsWidth);

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(
                width: visibleActionsWidth,
                child: SizedBox(
                  width: revealedWidth,
                  child: Row(
                    children: [
                      for (final action in actions)
                        Expanded(
                          child: _SwipeActionButton(
                            action: action,
                            maxWidth: actionWidth,
                            closeActions: closeActions,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: enabled
                ? (details) {
                    animationController.stop();
                    final newOffset = swipeOffset.value + details.delta.dx;
                    swipeOffset.value = newOffset.clamp(-totalActionsWidth, 0.0);
                  }
                : null,
            onHorizontalDragEnd: enabled
                ? (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity <= -250) {
                      openActions();
                    } else if (velocity >= 250) {
                      closeActions();
                    } else if (swipeOffset.value.abs() >= totalActionsWidth / 2) {
                      openActions();
                    } else {
                      closeActions();
                    }
                  }
                : null,
            behavior: HitTestBehavior.translucent,
            child: Transform.translate(
              offset: Offset(swipeOffset.value, 0),
              child: childBuilder(
                context,
                closeActions,
                isActionsOpen: isActionsOpen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.action,
    required this.maxWidth,
    required this.closeActions,
  });

  final RecentChatActionItem action;
  final double maxWidth;
  final VoidCallback closeActions;

  Color _backgroundColor(BuildContext context) {
    return switch (action.kind) {
      RecentChatActionKind.archive ||
      RecentChatActionKind.unarchive =>
        context.theme.appColors.quaternaryText,
      RecentChatActionKind.mute ||
      RecentChatActionKind.unmute =>
        context.theme.appColors.orangePeel,
      RecentChatActionKind.delete => context.theme.appColors.attentionRed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = maxWidth - 16.0.s;
    final backgroundColor = _backgroundColor(context);
    final foregroundColor = context.theme.appColors.onPrimaryAccent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final revealProgress = (constraints.maxWidth / maxWidth).clamp(0.0, 1.0);
        final labelProgress = Curves.easeOut.transform(
          ((revealProgress - 0.2) / 0.8).clamp(0.0, 1.0),
        );
        final blendedForeground = Color.lerp(
          backgroundColor,
          foregroundColor,
          labelProgress,
        )!;

        return Material(
          color: backgroundColor,
          child: InkWell(
            onTap: () async {
              closeActions();
              await action.onSelected();
            },
            child: ClipRect(
              child: OverflowBox(
                minWidth: maxWidth,
                maxWidth: maxWidth,
                child: SizedBox(
                  width: maxWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      action.icon.icon(
                        size: 22.0.s,
                        color: blendedForeground,
                      ),
                      SizedBox(height: 6.0.s),
                      SizedBox(
                        width: contentWidth,
                        child: Text(
                          action.label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: context.theme.appTextThemes.caption2.copyWith(
                            color: blendedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
