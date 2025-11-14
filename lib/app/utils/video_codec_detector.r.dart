// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/video_info_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_codec_detector.r.g.dart';

class VideoCodecDetector {
  const VideoCodecDetector({
    required this.videoInfoService,
  });

  final VideoInfoService videoInfoService;

  Future<String?> getVideoCodec(String videoPath) async {
    try {
      final codec = await videoInfoService.getVideoCodec(videoPath);
      Logger.log('Detected codec: $codec for path: $videoPath');
      return codec;
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
  return VideoCodecDetector(
    videoInfoService: ref.read(videoInfoServiceProvider),
  );
}
