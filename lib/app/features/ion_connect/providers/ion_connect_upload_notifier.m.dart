// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/file_storage_url_provider.r.dart';
import 'package:ion/app/features/ion_connect/utils/file_storage_utils.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/large_media_upload_service.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_upload_notifier.m.freezed.dart';
part 'ion_connect_upload_notifier.m.g.dart';

typedef UploadResult = ({FileMetadata fileMetadata, MediaAttachment mediaAttachment});

const int _largeFileThreshold = 1024 * 1024;

@riverpod
class IonConnectUploadNotifier extends _$IonConnectUploadNotifier {
  @override
  FutureOr<void> build() {}

  /// IMPORTANT:
  /// Uploading a file via this method only stores it on the relay and returns the metadata.
  /// It DOES NOT broadcast the metadata (FileMetadata) as a NIP-94 event (kind 1063).
  ///
  /// The developer is responsible for sending the FileMetadata to the relay manually
  /// after a successful upload.
  Future<UploadResult> upload(
    MediaFile file, {
    FileAlt? alt,
    EventSigner? customEventSigner,
    bool skipDimCheck = false,
    CancelToken? cancelToken,
  }) async {
    // Validate that the MIME type is supported
    final mimeType = file.mimeType;
    if (mimeType != null && !MimeType.isSupported(mimeType)) {
      throw UnsupportedError('Unsupported media MIME type: $mimeType');
    }

    if (!skipDimCheck && (file.width == null || file.height == null)) {
      throw UnknownFileResolutionException('File dimensions are missing');
    }
    final dimension = skipDimCheck ? null : '${file.width}x${file.height}';

    final url = await ref.read(fileStorageUrlProvider.future);

    final fileBytes = await File(file.path).readAsBytes();
    final isLargeFile = fileBytes.length >= _largeFileThreshold;

    // replace files with xfiles in the url for large files
    final uploadUrl = isLargeFile ? Uri.parse(url).replace(path: '/xfiles/').toString() : url;

    final authToken = await generateAuthorizationToken(
      ref: ref,
      url: uploadUrl,
      fileBytes: fileBytes,
      customEventSigner: customEventSigner,
      method: 'POST',
    );

    UploadResponse response;
    try {
      final uploader = isLargeFile ? _uploadLargeMultipart : _uploadSimpleMultipart;

      response = await uploader(
        url: uploadUrl,
        file: file,
        fileBytes: fileBytes,
        authToken: authToken,
        alt: alt,
        cancelToken: cancelToken,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: '[Upload] Upload failed isLarge=$isLargeFile url=$uploadUrl',
      );
      rethrow;
    }

    final fileMetadata = FileMetadata.fromUploadResponseTags(
      response.nip94Event.tags,
      mimeType: file.mimeType,
      originalMimeType: file.originalMimeType,
    );

    final mediaAttachment = MediaAttachment(
      url: fileMetadata.url,
      mimeType: fileMetadata.mimeType,
      dimension: dimension,
      originalFileHash: fileMetadata.originalFileHash,
      alt: alt,
      thumb: fileMetadata.thumb,
      duration: file.duration,
      originalMimeType: fileMetadata.originalMimeType,
    );

    return (fileMetadata: fileMetadata, mediaAttachment: mediaAttachment);
  }

  Future<UploadResponse> _uploadLargeMultipart({
    required String url,
    required MediaFile file,
    required Uint8List fileBytes,
    required String authToken,
    CancelToken? cancelToken,
    FileAlt? alt,
  }) async {
    final dio = ref.read(dioHttp2Provider);
    final feedConfig = await ref.watch(feedConfigProvider.future);

    return LargeMediaUploadService(
      dio: dio,
      maxConcurrentPartials: feedConfig.concurrentBigFileUploadChunks,
    ).upload(
      url: url,
      file: file,
      authToken: authToken,
      alt: alt,
      fileBytes: fileBytes,
      cancelToken: cancelToken,
    );
  }

  Future<UploadResponse> _uploadSimpleMultipart({
    required String url,
    required MediaFile file,
    required Uint8List fileBytes,
    required String authToken,
    FileAlt? alt,
    CancelToken? cancelToken,
  }) async {
    final fileName = file.name ?? file.basename;
    final multipartFile = MultipartFile.fromBytes(fileBytes, filename: fileName);

    final formData = FormData.fromMap({
      'file': multipartFile,
      'caption': fileName,
      if (alt != null) 'alt': alt.toShortString(),
      'size': multipartFile.length,
      'content_type': file.mimeType,
    });

    try {
      final response = await ref.read(dioProvider).post<dynamic>(
            url,
            data: formData,
            options: Options(
              headers: {'Authorization': authToken},
            ),
            cancelToken: cancelToken,
          );

      final uploadResponse =
          UploadResponse.fromJson(json.decode(response.data as String) as Map<String, dynamic>);

      if (uploadResponse.status != 'success') {
        throw Exception(uploadResponse.message);
      }
      return uploadResponse;
    } catch (error) {
      throw FileUploadException(error, url: url);
    }
  }
}

@freezed
class UploadResponse with _$UploadResponse {
  const factory UploadResponse({
    required String status,
    required String message,
    @JsonKey(name: 'nip94_event') required UploadResponseNip94Event nip94Event,
  }) = _UploadResponse;

  factory UploadResponse.fromJson(Map<String, dynamic> json) => _$UploadResponseFromJson(json);
}

@freezed
class UploadResponseNip94Event with _$UploadResponseNip94Event {
  const factory UploadResponseNip94Event({
    required String content,
    required List<List<String>> tags,
  }) = _UploadResponseNip94Event;

  factory UploadResponseNip94Event.fromJson(Map<String, dynamic> json) =>
      _$UploadResponseNip94EventFromJson(json);
}
