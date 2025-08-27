// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/media_service/media_upload_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_upload_provider.r.g.dart';

@riverpod
MediaUploadService mediaUpload(
  Ref ref, {
  required String fileAlt,
  ImageCompressionSettings? imageCompressionSettings,
}) {
  return MediaUploadService(
    ref: ref,
    fileAlt: fileAlt,
    imageCompressionSettings:
        imageCompressionSettings ?? const ImageCompressionSettings(shouldCompressGif: true),
  );
}
