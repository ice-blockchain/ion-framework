// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/services/compressors/image_compressor.r.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/media_service/blurhash_service.r.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

class MediaUploadService {
  MediaUploadService({
    required this.ref,
    required this.fileAlt,
    this.imageCompressionSettings = const ImageCompressionSettings(shouldCompressGif: true),
  });
  final Ref ref;
  final FileAlt fileAlt;
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
    final blurhash = await ref.read(generateBlurhashProvider(compressedImage));
    final uploadResult = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
          compressedImage,
          alt: fileAlt,
        );
    final mediaAttachment = uploadResult.mediaAttachment.copyWith(
      blurhash: blurhash,
    );
    final fileMetadata = uploadResult.fileMetadata.copyWith(
      blurhash: blurhash,
    );
    return (fileMetadatas: [fileMetadata], mediaAttachment: mediaAttachment);
  }

  Future<({List<FileMetadata> fileMetadatas, MediaAttachment mediaAttachment})> uploadVideo(
    MediaFile file,
  ) async {
    final videoCompressor = ref.read(videoCompressorProvider);
    final compressedVideo = await videoCompressor.compress(file);
    final videoUploadResult = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
          compressedVideo,
          alt: fileAlt,
        );
    final thumbImage = await videoCompressor.getThumbnail(compressedVideo, thumb: file.thumb);
    final thumbUploadResult = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
          thumbImage,
          alt: fileAlt,
        );
    final thumbUrl = thumbUploadResult.fileMetadata.url;
    final blurhash = await ref.read(generateBlurhashProvider(thumbImage));
    final mediaAttachment = videoUploadResult.mediaAttachment.copyWith(
      thumb: thumbUrl,
      image: thumbUrl,
      blurhash: blurhash,
    );
    final videoFileMetadata = videoUploadResult.fileMetadata.copyWith(
      thumb: thumbUrl,
      image: thumbUrl,
      blurhash: blurhash,
    );
    return (
      fileMetadatas: [videoFileMetadata, thumbUploadResult.fileMetadata],
      mediaAttachment: mediaAttachment,
    );
  }
}
