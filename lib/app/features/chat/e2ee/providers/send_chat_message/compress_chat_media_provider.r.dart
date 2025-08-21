// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/services/compressors/compressor.r.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compress_chat_media_provider.r.g.dart';

@Riverpod(keepAlive: true)
Raw<Future<MediaFile>> compressChatMedia(
  Ref ref,
  MediaFile mediaFile, {
  Completer<FFmpegSession>? sessionIdCompleter,
}) async {
  final mediaType = MediaType.fromMimeType(mediaFile.mimeType ?? '');

  final compressor = ref.watch(compressorProvider(mediaType));
  if (mediaType == MediaType.image) {
    return compressor.compress(
      mediaFile,
      settings: const ImageCompressionSettings(shouldCompressGif: true),
    );
  }

  if (mediaType == MediaType.video) {
    return (compressor as VideoCompressor)
        .compress(mediaFile, sessionIdCompleter: sessionIdCompleter);
  }

  return compressor.compress(mediaFile);
}
