// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mute_provider.r.g.dart';

@Riverpod(keepAlive: true)
class GlobalMuteNotifier extends _$GlobalMuteNotifier {
  static const _focusChannel = MethodChannel('audio_focus_channel');
  static const _volumeChannel = MethodChannel('audio_volume_channel');

  @override
  bool build() {
    _setupMethodChannelHandler();
    _initializeAudioFocus();
    return true;
  }

  void _setupMethodChannelHandler() {
    _focusChannel.setMethodCallHandler((call) async {
      return null;
    });
    _volumeChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onVolumeUp':
          if (state) {
            await toggle();
          }
          return null;

        default:
          return null;
      }
    });
  }

  Future<void> _initializeAudioFocus() async {
    await _focusChannel.invokeMethod<bool>('initAudioFocus');
  }

  Future<void> toggle() async {
    final willBeMuted = !state;

    var success = false;
    var retries = 0;

    while (!success && retries < 3) {
      if (willBeMuted) {
        final result = await _focusChannel.invokeMethod<bool>('abandonAudioFocus');
        success = result ?? false;
      } else {
        final result = await _focusChannel.invokeMethod<bool>('requestAudioFocus');
        success = result ?? false;
      }

      if (!success) {
        retries++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    if (success) {
      state = willBeMuted;
    }
  }
}
