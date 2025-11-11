// SPDX-License-Identifier: ice License 1.0

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/providers/active_audio_message_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/services/audio_wave_playback_service/audio_wave_playback_service.r.dart';

/// Hook that sets up audio playback for a message.
///
/// Handles:
/// - Player initialization
/// - State subscriptions
/// - Active audio message listening
///
/// Returns a record containing:
/// - [audioPlaybackState]: A [ValueNotifier] that tracks the current playback state
/// - [playerWaveStyle]: The [PlayerWaveStyle] used for the audio waveform
/// - [playerId]: The calculated player ID
({
  ValueNotifier<PlayerState?> audioPlaybackState,
  PlayerWaveStyle playerWaveStyle,
  String? playerId,
}) useAudioPlaybackSetup({
  required String? localMediaPath,
  required PlayerController audioPlaybackController,
  required Color liveWaveColor,
  required BuildContext context,
  required WidgetRef ref,
  String? eventMessageId,
  EventReference? eventReference,
}) {
  final audioPlaybackState = useState<PlayerState?>(null);

  final playerId = useMemoized(
    () =>
        eventMessageId ??
        (eventReference is ImmutableEventReference
            ? eventReference.eventId
            : eventReference?.toString()),
    [eventMessageId, eventReference],
  );

  final playerWaveStyle = useMemoized(
    () => PlayerWaveStyle(
      spacing: 2.0.s,
      waveThickness: 1.0.s,
      seekLineColor: Colors.transparent,
      fixedWaveColor: context.theme.appColors.sheetLine,
      liveWaveColor: liveWaveColor,
    ),
    [liveWaveColor],
  );

  // Initialize audio player when path is available
  useEffect(
    () {
      if (localMediaPath == null || playerId == null) {
        return null;
      }

      ref.read(audioWavePlaybackServiceProvider).initializePlayer(
            playerId,
            localMediaPath,
            audioPlaybackController,
            playerWaveStyle,
          );

      final stateSubscription = audioPlaybackController.onPlayerStateChanged.listen((event) {
        if (context.mounted) {
          if (event != PlayerState.stopped) {
            audioPlaybackState.value = event;
          }
        }
      });

      final completionSubscription = audioPlaybackController.onCompletion.listen((event) {
        if (context.mounted) {
          ref.read(activeAudioMessageProvider.notifier).activeAudioMessage = null;
        }
      });

      return () {
        stateSubscription.cancel();
        completionSubscription.cancel();
      };
    },
    [localMediaPath, playerId],
  );

  // Listen to active audio message changes
  useEffect(
    () {
      if (playerId == null) {
        return null;
      }

      final subscription = ref.listenManual(activeAudioMessageProvider, (previous, next) {
        if (next == playerId) {
          audioPlaybackController.startPlayer();
        } else {
          audioPlaybackController.pausePlayer();
        }
      });
      return subscription.close;
    },
    [playerId],
  );

  return (
    audioPlaybackState: audioPlaybackState,
    playerWaveStyle: playerWaveStyle,
    playerId: playerId,
  );
}
