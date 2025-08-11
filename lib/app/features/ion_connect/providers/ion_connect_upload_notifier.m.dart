// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
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

  Future<UploadResult> upload(
    MediaFile file, {
    FileAlt? alt,
    EventSigner? customEventSigner,
    bool skipDimCheck = false,
  }) async {
    if (!skipDimCheck && (file.width == null || file.height == null)) {
      throw UnknownFileResolutionException('File dimensions are missing');
    }
    final dimension = skipDimCheck ? null : '${file.width}x${file.height}';

    final url = await ref.read(fileStorageUrlProvider.future);

    final fileBytes = await File(file.path).readAsBytes();
    final isLargeFile = fileBytes.length >= _largeFileThreshold;

    // replace files with xfiles in the url for large files
    final uploadUrl = isLargeFile ? url.replaceFirst('files', 'xfiles/') : url;

    final authorizationToken = await generateAuthorizationToken(
      ref: ref,
      url: uploadUrl,
      fileBytes: fileBytes,
      customEventSigner: customEventSigner,
      method: 'POST',
    );

    UploadResponse response;
    try {
      response = isLargeFile
          ? await _uploadLargeMultipart(
              url: uploadUrl,
              file: file,
              authorizationToken: authorizationToken,
              alt: alt,
            )
          : await _uploadSimpleMultipart(
              url: url,
              file: file,
              fileBytes: fileBytes,
              authorizationToken: authorizationToken,
              alt: alt,
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
    );

    final mediaAttachment = MediaAttachment(
      url: fileMetadata.url,
      mimeType: fileMetadata.mimeType,
      dimension: dimension,
      originalFileHash: fileMetadata.originalFileHash,
      alt: alt,
      thumb: fileMetadata.thumb,
      duration: file.duration,
    );

    return (fileMetadata: fileMetadata, mediaAttachment: mediaAttachment);
  }

  Future<UploadResponse> _uploadLargeMultipart({
    required String url,
    required MediaFile file,
    required String authorizationToken,
    FileAlt? alt,
  }) async {
    final dio = Dio()
      ..options.baseUrl = url
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(),
      );

    final isLogApp = ref.read(featureFlagsProvider.notifier).get(LoggerFeatureFlag.logApp);
    if (isLogApp) {
      dio.interceptors.add(
        LogInterceptor(),
      );
    }

    return LargeMediaUploadService(
      dio: dio,
    ).upload(
      url: url,
      file: file,
      authorizationToken: authorizationToken,
      alt: alt,
    );
  }

  Future<UploadResponse> _uploadSimpleMultipart({
    required String url,
    required MediaFile file,
    required Uint8List fileBytes,
    required String authorizationToken,
    FileAlt? alt,
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
              headers: {'Authorization': authorizationToken},
            ),
          );

      final uploadResponse =
          UploadResponse.fromJson(json.decode(response.data as String) as Map<String, dynamic>);

      if (uploadResponse.status != 'success') {
        throw Exception(uploadResponse.message);
      }
      return uploadResponse;
    } catch (e) {
      throw FileUploadException(e, url: url);
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
