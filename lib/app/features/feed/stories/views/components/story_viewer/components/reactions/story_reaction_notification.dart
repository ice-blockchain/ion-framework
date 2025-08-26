// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/story_pause_visibility/story_pause_visibility_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/views/components/message_items/components.dart';
import 'package:ion/app/features/feed/stories/providers/story_reply_notification_provider.m.dart';

class StoryReplyNotification extends ConsumerWidget {
  const StoryReplyNotification({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyReplyNotification = ref.watch(storyReplyNotificationControllerProvider);

    final i18n = context.i18n;
    final appTextThemes = context.theme.appTextThemes;
    final emoji = storyReplyNotification.selectedEmoji;
    final notificationColor = context.theme.appColors.onPrimaryAccent;

    return PositionedDirectional(
      top: 70.0.s,
      start: 0.0.s,
      end: 0.0.s,
      child: StoryPauseVisibilityWrapper(
        child: Animate(
          key: ValueKey(storyReplyNotification.selectedEmoji),
          onComplete: (_) {
            ref.read(storyReplyNotificationControllerProvider.notifier).hideNotification();
          },
          effects: [
            FadeEffect(duration: 300.ms),
            ThenEffect(delay: 2.seconds),
            FadeEffect(
              begin: 1,
              end: 0,
              duration: 300.ms,
            ),
          ],
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0.s),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0.s,
                    vertical: 8.0.s,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16.0.s),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emoji != null ? i18n.reaction_was_sent : i18n.reply_was_sent,
                        style: appTextThemes.body2.copyWith(color: notificationColor),
                      ),
                      if (emoji != null)
                        Text(
                          ' $emoji',
                          style: TextStyle(fontSize: 16.0.s).platformEmojiAware(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
