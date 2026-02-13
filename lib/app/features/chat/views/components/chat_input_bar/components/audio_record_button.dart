// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/views/components/chat_input_bar/components/recording_overlay.dart';
import 'package:ion/generated/assets.gen.dart';

class AudioRecordButton extends ConsumerWidget {
  const AudioRecordButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(10.s, 4.s, 6.s, 4.s),
      child: Assets.svg.iconChatMicrophone.icon(
        color: context.theme.appColors.primaryText,
        size: 24.0.s,
      ),
    );
  }
}

class AudioRecordingButton extends HookConsumerWidget {
  const AudioRecordingButton({
    required this.paddingBottom,
    required this.onSubmitted,
    required this.onResumeRecording,
    required this.isKeyboardVisible,
    super.key,
  });

  final double paddingBottom;
  final Future<void> Function() onSubmitted;
  final Future<void> Function() onResumeRecording;
  final bool isKeyboardVisible;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayEntry = useRef<OverlayEntry?>(null);

    useEffect(
      () {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          final overlay = Overlay.of(context);
          overlayEntry.value = OverlayEntry(
            builder: (context) {
              return RecordingOverlay(
                isKeyboardVisible: isKeyboardVisible,
                paddingBottom: paddingBottom,
                onSubmitted: onSubmitted,
                onResumeRecording: onResumeRecording,
              );
            },
          );
          overlay.insert(overlayEntry.value!);
        });
        return () {
          overlayEntry.value?.remove();
          overlayEntry.value = null;
        };
      },
      [paddingBottom],
    );

    return const SizedBox.shrink();
  }
}
