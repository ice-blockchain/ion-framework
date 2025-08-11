// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/messaging_bottom_bar_state_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class RecordingOverlay extends ConsumerWidget {
  const RecordingOverlay({
    required this.paddingBottom,
    required this.onSubmitted,
    required this.onResumeRecording,
    super.key,
  });

  final double paddingBottom;
  final Future<void> Function() onSubmitted;
  final Future<void> Function() onResumeRecording;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceRecordingState = ref.watch(voiceRecordingActiveStateProvider);

    return PositionedDirectional(
      bottom: MediaQuery.viewInsetsOf(context).bottom + 8.0.s,
      end: 14.0.s,
      child: SafeArea(
        child: Container(
          width: 32.0.s,
          decoration: BoxDecoration(
            color: context.theme.appColors.onTertiaryFill,
            borderRadius: BorderRadius.all(
              Radius.circular(20.0.s),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (voiceRecordingState.isLocked)
                GestureDetector(
                  onTap: () {
                    ref.read(voiceRecordingActiveStateProvider.notifier).pause();
                  },
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(top: 8.0.s),
                    child: Assets.svg.iconVideoPause.icon(
                      color: context.theme.appColors.primaryAccent,
                      size: 20.0.s,
                    ),
                  ),
                )
              else if (voiceRecordingState.isPaused)
                GestureDetector(
                  onTap: onResumeRecording,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(top: 8.0.s),
                    child: Assets.svg.iconChatMicrophone.icon(
                      color: context.theme.appColors.primaryAccent,
                      size: 20.0.s,
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsetsDirectional.only(top: 4.0.s),
                  child: Container(
                    padding: EdgeInsets.all(4.0.s),
                    decoration: BoxDecoration(
                      color: paddingBottom > 20
                          ? context.theme.appColors.primaryAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0.s),
                    ),
                    child: Assets.svg.linearSecurityLockKeyholeUnlocked.icon(
                      color: paddingBottom > 20
                          ? context.theme.appColors.onPrimaryAccent
                          : context.theme.appColors.primaryAccent,
                      size: 20.0.s,
                    ),
                  ),
                ),
              SizedBox(height: 18.0.s),
              Container(
                padding: EdgeInsets.all(4.0.s),
                decoration: BoxDecoration(
                  color: context.theme.appColors.primaryAccent,
                  borderRadius: BorderRadius.circular(12.0.s),
                ),
                child: voiceRecordingState.isPaused
                    ? GestureDetector(
                        onTap: onSubmitted,
                        child: Assets.svg.iconChatSendmessage.icon(
                          color: context.theme.appColors.onPrimaryAccent,
                          size: 24.0.s,
                        ),
                      )
                    : Assets.svg.iconChatMicrophone.icon(
                        color: context.theme.appColors.onPrimaryAccent,
                        size: 24.0.s,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
