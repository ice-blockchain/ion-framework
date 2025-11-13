// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/blurhash_service.r.dart';
import 'package:ion/app/services/media_service/ffmpeg_args/ffmpeg_scale_arg.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';

class MediaUploadService {
  MediaUploadService({
    required this.ref,
    required this.fileAlt,
    this.imageCompressionSettings = const ImageCompressionSettings(shouldCompressGif: true),
  });

  final Ref ref;
  final String fileAlt;
  final ImageCompressionSettings imageCompressionSettings;

  Future<({List<FileMetadata> fileMetadatas, MediaAttachment mediaAttachment})> uploadMedia(
    MediaFile mediaFile,
  ) async {
    final mimeType = mediaFile.mimeType;
    if (mimeType == null) {
      throw FileUploadException('Failed to upload media, mimeType is null', url: mediaFile.path);
    }

    final mediaType = MediaType.fromMimeType(mimeType);
    switch (mediaType) {
      case MediaType.image:
        return uploadImage(mediaFile);
      case MediaType.video:
        return uploadVideo(mediaFile);
      case MediaType.audio:
      case MediaType.unknown:
        throw Exception('Unknown media type');
    }
  }

  Future<({List<FileMetadata> fileMetadatas, MediaAttachment mediaAttachment})> uploadImage(
    MediaFile file,
  ) async {
    var compressedImage = file;
    compressedImage = await ref.read(imageCompressorProvider).compress(
          file,
          settings: imageCompressionSettings,
        );
    var thumbSourceFile = compressedImage;
    //handling animated gif files as videos to extract thumb image
    if (compressedImage.mimeType == MimeType.gif.value) {
      final videoCompressor = ref.read(videoCompressorProvider);
      final compressedVideo = await videoCompressor.compress(file);
      thumbSourceFile = await videoCompressor.getThumbnail(compressedVideo, thumb: file.thumb);
    }

    final thumbImage = await ref.read(imageCompressorProvider).scaleImage(
          thumbSourceFile,
        );
    final thumbUploadResult = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
          thumbImage,
          alt: fileAlt,
        );

    final uploadResult = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
          compressedImage,
          alt: fileAlt,
        );

    final blurhash = await ref.read(generateBlurhashProvider(compressedImage));

    final mediaAttachment = uploadResult.mediaAttachment.copyWith(
      blurhash: blurhash,
      thumb: thumbUploadResult.fileMetadata.url,
      image: uploadResult.fileMetadata.url,
    );
    final fileMetadata = uploadResult.fileMetadata.copyWith(
      blurhash: blurhash,
      thumb: thumbUploadResult.fileMetadata.url,
      image: uploadResult.fileMetadata.url,
    );
    final thumbFileMetadata = thumbUploadResult.fileMetadata.copyWith(
      url: thumbUploadResult.fileMetadata.url,
    );
    return (fileMetadatas: [fileMetadata, thumbFileMetadata], mediaAttachment: mediaAttachment);
  }

  Future<({List<FileMetadata> fileMetadatas, MediaAttachment mediaAttachment})> uploadVideo(
    MediaFile file,
  ) async {
    try {
      final videoCompressor = ref.read(videoCompressorProvider);

      final compressedVideo = await videoCompressor.compress(file);

      final videoUploadResult = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
            compressedVideo,
            alt: fileAlt,
          );

      final videoImage = await videoCompressor.getThumbnail(compressedVideo, thumb: file.thumb);

      final videoImageUploadResult =
          await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
                videoImage,
                alt: fileAlt,
              );

      final thumbImage = await ref
          .read(imageCompressorProvider)
          .scaleImage(videoImage, scaleResolution: FfmpegScaleArg.p480);

      final thumbImageUploadResult =
          await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
                thumbImage,
                alt: fileAlt,
              );

      final imageUrl = videoImageUploadResult.fileMetadata.url;
      final thumbUrl = thumbImageUploadResult.fileMetadata.url;
      final blurhash = await ref.read(generateBlurhashProvider(videoImage));

      final mediaAttachment = videoUploadResult.mediaAttachment.copyWith(
        image: imageUrl,
        thumb: thumbUrl,
        blurhash: blurhash,
      );
      final videoFileMetadata = videoUploadResult.fileMetadata.copyWith(
        thumb: thumbUrl,
        image: imageUrl,
        blurhash: blurhash,
      );
      return (
        fileMetadatas: [videoFileMetadata, videoImageUploadResult.fileMetadata],
        mediaAttachment: mediaAttachment,
      );
    } catch (error, stackTrace) {
      Logger.error(error, stackTrace: stackTrace, message: 'Error during video upload');
      await SentryService.logException(
        error,
        stackTrace: stackTrace,
        tag: 'video_upload_error',
      );
      rethrow;
    }
  }
}
