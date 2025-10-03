// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/providers/messaging_bottom_bar_state_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/audio_record_button.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/send_button.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';

class ActionButton extends HookConsumerWidget {
  const ActionButton({
    required this.textFieldController,
    required this.onSubmitted,
    required this.recorderController,
    super.key,
  });

  final TextEditingController textFieldController;
  final Future<void> Function()? onSubmitted;
  final RecorderController recorderController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecordingCancelled = useRef<bool>(false);
    final paddingBottom = useState<double>(0);
    final hasText = useState<bool>(false);
    final voiceRecordingState = ref.watch(voiceRecordingActiveStateProvider);

    useEffect(
      () {
        void onTextChanged() {
          hasText.value = textFieldController.text.trim().isNotEmpty;
        }

        textFieldController.addListener(onTextChanged);

        return () {
          textFieldController.removeListener(onTextChanged);
        };
      },
      [],
    );

    final onSend = useCallback(() async {
      ref.invalidate(voiceRecordingActiveStateProvider);
      await onSubmitted?.call();
    });

    final startRecording = useCallback(
      () async {
        await recorderController.record(bitRate: 44100);
      },
      [recorderController],
    );

    Widget subButton() {
      if (hasText.value) {
        return SendButton(
          onSend: onSend,
          disabled: onSubmitted == null,
        );
      } else if (!voiceRecordingState.isIdle) {
        return AudioRecordingButton(
          paddingBottom: paddingBottom.value,
          onSubmitted: onSend,
          onResumeRecording: () async {
            ref.read(voiceRecordingActiveStateProvider.notifier).lock();
            await startRecording();
          },
        );
      } else {
        return const AudioRecordButton();
      }
    }

    return GestureDetector(
      onLongPressStart: (details) async {
        if (!hasText.value) {
          await ref.read(permissionsProvider.notifier).checkPermission(Permission.microphone);
          final status = ref.read(
            permissionsProvider.select((value) => value.permissions[Permission.microphone]),
          );
          if (status == PermissionStatus.granted) {
            isRecordingCancelled.value = false;
            await startRecording();
            if (isRecordingCancelled.value) {
              if (context.mounted) {
                ref.invalidate(voiceRecordingActiveStateProvider);
              }
              await recorderController.stop();
              return;
            }
            if (context.mounted) {
              ref.read(voiceRecordingActiveStateProvider.notifier).start();
              unawaited(HapticFeedback.lightImpact());
            }
          } else {
            unawaited(
              ref.read(permissionsProvider.notifier).requestPermission(Permission.microphone),
            );
          }
        }
      },
      onLongPressMoveUpdate: (details) {
        if (details.localOffsetFromOrigin.dy < 0) {
          paddingBottom.value = details.localOffsetFromOrigin.dy * -1;
        } else {
          paddingBottom.value = 0;
        }
      },
      onLongPressEnd: (details) {
        if (recorderController.elapsedDuration > Duration.zero) {
          if (paddingBottom.value > 20) {
            ref.read(voiceRecordingActiveStateProvider.notifier).lock();
            paddingBottom.value = 0;
          } else {
            ref.read(voiceRecordingActiveStateProvider.notifier).pause();
          }
        } else {
          isRecordingCancelled.value = true;
        }
      },
      child: AbsorbPointer(
        absorbing: ref.watch(voiceRecordingActiveStateProvider).isLocked,
        child: subButton(),
      ),
    );
  }
}
