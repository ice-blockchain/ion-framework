// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/providers/messaging_bottom_bar_state_provider.r.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/cancel_record_button.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/delete_audio_button.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/duration_text.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/recording_indicator.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/voice_message_preview_tile.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/date.dart';
import 'package:mime/mime.dart';

class ChatInputBarRecordingOverlay extends HookConsumerWidget {
  const ChatInputBarRecordingOverlay({
    required this.onRecordingFinished,
    required this.onCancelled,
    required this.recorderController,
    super.key,
  });

  final Future<String> Function(MediaFile mediaFile) onRecordingFinished;
  final VoidCallback onCancelled;
  final RecorderController recorderController;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceRecordingState = ref.watch(voiceRecordingActiveStateProvider);
    final duration = useState<Duration>(Duration.zero);
    final previousDuration = useRef<Duration>(Duration.zero);
    final audioPath = useState<String?>(null);

    ref.listen(voiceRecordingActiveStateProvider, (_, state) {
      if (state.isIdle) {
        previousDuration.value = Duration.zero;
        audioPath.value = null;
      }
    });

    useEffect(
      () {
        final recorderStateSubscription = recorderController.onRecorderStateChanged.listen((state) {
          if (state == RecorderState.stopped) {
            previousDuration.value += recorderController.recordedDuration;
          } else {
            audioPath.value = null;
          }
        });

        final durationSubscription = recorderController.onCurrentDuration.listen((currentDuration) {
          duration.value = currentDuration + previousDuration.value;
          if (currentDuration.inSeconds ==
              EncryptedDirectMessageData.audioMessageDurationLimitInSeconds) {
            ref.read(voiceRecordingActiveStateProvider.notifier).pause();
            return;
          }
        });

        return () {
          durationSubscription.cancel();
          previousDuration.value = Duration.zero;
          recorderStateSubscription.cancel();
          recorderController.reset();
        };
      },
      [],
    );

    useEffect(
      () {
        if (voiceRecordingState.isPaused) {
          recorderController.stop().then((path) async {
            if (path == null) {
              return;
            }

            final mimetype = lookupMimeType(path);
            final newAudioPath =
                await onRecordingFinished(MediaFile(path: path, mimeType: mimetype));

            audioPath.value = newAudioPath;
          });
        }
        return null;
      },
      [voiceRecordingState],
    );

    if (voiceRecordingState.isIdle) {
      return const SizedBox.shrink();
    }

    return Container(
      color: context.theme.appColors.onPrimaryAccent,
      constraints: BoxConstraints(
        minHeight: 32.0.s,
      ),
      width: MediaQuery.sizeOf(context).width,
      padding: EdgeInsetsDirectional.only(end: 48.0.s),
      child: Row(
        children: [
          if (voiceRecordingState.isPaused) ...[
            DeleteAudioButton(
              onPressed: onCancelled,
            ),
            SizedBox(width: 6.0.s),
            if (audioPath.value != null)
              VoiceMessagePreviewTile(
                duration: formatDuration(duration.value),
                path: audioPath.value!,
              ),
          ] else ...[
            CancelRecordButton(recorderController: recorderController),
            const Spacer(),
            const RecordingRedIndicator(),
            SizedBox(width: 4.0.s),
            DurationText(duration: formatDuration(duration.value)),
          ],
        ],
      ),
    );
  }
}
