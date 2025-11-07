// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_codec_detector.r.g.dart';

class VideoCodecDetector {
  const VideoCodecDetector();

  static const _channel = MethodChannel('ion/video_codec');

  Future<String?> getVideoCodec(String videoPath) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'getVideoCodec',
        {'videoPath': videoPath},
      );
      Logger.log('Detected codec: $result for path: $videoPath');
      return result;
    } catch (e) {
      Logger.log(
        'Failed to detect video codec',
        error: e,
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }

  Future<bool> isAV1Video(String videoPath) async {
    final codec = await getVideoCodec(videoPath);
    if (codec == null) return false;

    final isAV1 = codec.toLowerCase().contains('av01') || codec.toLowerCase().contains('av1');
    return isAV1;
  }
}

@riverpod
VideoCodecDetector videoCodecDetector(Ref ref) {
  return const VideoCodecDetector();
}
