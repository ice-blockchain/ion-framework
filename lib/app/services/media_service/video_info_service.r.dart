// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/services/logger/logger.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_info_service.r.g.dart';

class VideoInfoService {
  Future<({int width, int height, Duration duration, int? bitrate, double? frameRate})>
      getVideoInformation(
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

    double? frameRate;
    try {
      final avgFrameRateString = videoStream.getAverageFrameRate();
      if (avgFrameRateString != null && avgFrameRateString.isNotEmpty) {
        final parts = avgFrameRateString.split('/');
        if (parts.length == 2) {
          final numerator = double.tryParse(parts[0]);
          final denominator = double.tryParse(parts[1]);
          if (numerator != null && denominator != null && denominator != 0) {
            frameRate = numerator / denominator;
          }
        }
      }
    } catch (e) {
      Logger.warning('Failed to extract frame rate for video: $videoPath, using default value');
    }

    return (
      width: width,
      height: height,
      duration: duration,
      bitrate: bitrate,
      frameRate: frameRate
    );
  }

  Future<String?> getVideoCodec(String videoPath) async {
    try {
      final infoSession = await FFprobeKit.getMediaInformation(videoPath);
      final info = infoSession.getMediaInformation();
      if (info == null) {
        return null;
      }
      final streams = info.getStreams();
      if (streams.isEmpty) {
        return null;
      }

      final videoStream = streams.firstWhere(
        (s) => s.getType() == 'video',
        orElse: () => throw Exception('No video stream found'),
      );

      return videoStream.getCodec();
    } catch (e) {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
VideoInfoService videoInfoService(Ref ref) => VideoInfoService();
