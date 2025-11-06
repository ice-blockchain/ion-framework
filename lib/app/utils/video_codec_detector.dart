// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/services.dart';
import 'package:ion/app/services/logger/logger.dart';

class VideoCodecDetector {
  static const _channel = MethodChannel('ion/video_codec');

  static Future<String?> getVideoCodec(String videoPath) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'getVideoCodec',
        {'videoPath': videoPath},
      );
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

  static Future<bool> isAV1Video(String videoPath) async {
    final codec = await getVideoCodec(videoPath);
    if (codec == null) return false;

    return codec.toLowerCase().contains('av01') || codec.toLowerCase().contains('av1');
  }
}
