// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_info_service.r.g.dart';

class VideoInfoService {
  Future<({int width, int height, Duration duration, int? bitrate})> getVideoInformation(
    String videoPath,
  ) async {
    final infoSession = await FFprobeKit.getMediaInformation(videoPath);
    final info = infoSession.getMediaInformation();
    if (info == null) {
      throw UnknownFileResolutionException(
        'No media information found for: $videoPath',
      );
    }
    final streams = info.getStreams();
    if (streams.isEmpty) {
      throw UnknownFileResolutionException(
        'No streams found in media: $videoPath',
      );
    }

    final videoStream = streams.firstWhere(
      (s) => s.getType() == 'video',
      orElse: () => throw UnknownFileResolutionException(
        'No video stream found in file: $videoPath',
      ),
    );

    final width = videoStream.getWidth();
    final height = videoStream.getHeight();
    if (width == null || height == null) {
      throw UnknownFileResolutionException(
        'Could not determine video resolution for: $videoPath',
      );
    }

    final durationString = info.getDuration();
    if (durationString == null) {
      throw UnknownFileDurationException(
        'Could not find video duration string for: $videoPath',
      );
    }

    final duration = Duration(milliseconds: (double.parse(durationString) * 1000).round());

    final bitrateString = videoStream.getBitrate();
    final bitrate = bitrateString != null ? int.tryParse(bitrateString) : null;

    return (width: width, height: height, duration: duration, bitrate: bitrate);
  }
}

@Riverpod(keepAlive: true)
VideoInfoService videoInfoService(Ref ref) => VideoInfoService();
