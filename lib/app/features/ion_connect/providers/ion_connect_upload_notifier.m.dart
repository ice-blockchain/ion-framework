// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/features/core/providers/dio_provider.r.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/file_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/file_storage_url_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_auth_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relays_replica_delay_provider.m.dart';
import 'package:ion/app/features/ion_connect/utils/file_storage_utils.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/logger/websocket_tracker.dart';
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
    String? alt,
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

    UploadResponse response;
    try {
      final uploader = isLargeFile ? _uploadLargeMultipart : _uploadSimpleMultipart;

      response = await _postWithRetry(
        uploader: uploader,
        url: uploadUrl,
        file: file,
        fileBytes: fileBytes,
        alt: alt,
        cancelToken: cancelToken,
        customEventSigner: customEventSigner,
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

  /// Generic retry wrapper that accepts any uploader function
  /// Handles one-shot retry with delay setting for relay auth errors
  Future<UploadResponse> _postWithRetry({
    required Future<UploadResponse> Function({
      required String url,
      required MediaFile file,
      required Uint8List fileBytes,
      String? alt,
      CancelToken? cancelToken,
      EventSigner? customEventSigner,
    }) uploader,
    required String url,
    required MediaFile file,
    required Uint8List fileBytes,
    String? alt,
    CancelToken? cancelToken,
    EventSigner? customEventSigner,
  }) async {
    try {
      final result = await uploader(
        url: url,
        file: file,
        fileBytes: fileBytes,
        alt: alt,
        cancelToken: cancelToken,
        customEventSigner: customEventSigner,
      );
      Logger.info('NOSTR.HTTP upload successful on first try - first-try-ok');
      return result;
    } catch (error) {
      if (_isOnBehalfAttestationError(error)) {
        // Set delay and retry once, token will include 10100 attestation
        ref.read(relaysReplicaDelayProvider.notifier).setDelay();
        Logger.info('NOSTR.HTTP retrying upload with 10100 attestation - relay-auth-err-retry');
        final uploadResponse = await uploader(
          url: url,
          file: file,
          fileBytes: fileBytes,
          alt: alt,
          cancelToken: cancelToken,
          customEventSigner: customEventSigner,
        );

        return uploadResponse;
      } else {
        Logger.warning(
          'err type=${error.runtimeType} code=${(error is DioException) ? (error.response?.statusCode ?? 0) : -1} msg="${(error is DioException) ? (error.response?.data is Map ? (error.toString()) : error.response?.data?.toString() ?? (error.message ?? '')) : error.toString()}"',
        );
        Logger.warning(
          'HARD CALL ON CATCH',
        );
        // Set delay and retry once, token will include 10100 attestation
        ref.read(relaysReplicaDelayProvider.notifier).setDelay();
        Logger.info('NOSTR.HTTP retrying upload with 10100 attestation - relay-auth-err-retry');
        final uploadResponse = await uploader(
          url: url,
          file: file,
          fileBytes: fileBytes,
          alt: alt,
          cancelToken: cancelToken,
          customEventSigner: customEventSigner,
        );
        Logger.info('HARD CALL DONE retry successful');

        return uploadResponse;
      }
    }
  }

  // Simple multipart uploader that generates its own token
  Future<UploadResponse> _uploadSimpleMultipart({
    required String url,
    required MediaFile file,
    required Uint8List fileBytes,
    String? alt,
    CancelToken? cancelToken,
    EventSigner? customEventSigner,
  }) async {
    // Generate auth token with conditional 10100 attestation
    final authToken = await generateAuthorizationToken(
      ref: ref,
      url: url,
      method: 'POST',
      fileBytes: fileBytes,
      customEventSigner: customEventSigner,
    );

    final fileName = file.name ?? file.basename;
    final multipartFile = MultipartFile.fromBytes(fileBytes, filename: fileName);

    final formData = FormData.fromMap({
      'file': multipartFile,
      'caption': fileName,
      if (alt != null) 'alt': alt,
      'size': multipartFile.length,
      'content_type': file.mimeType,
    });

    //LOGGER: Extract values for logging
    final uri = Uri.parse(url);
    final host = uri.authority.isNotEmpty ? uri.authority : uri.host;
    final nip98Pubkey = customEventSigner?.publicKey ??
        (await ref.read(currentUserIonConnectEventSignerProvider.future))?.publicKey;
    final wsAuthPubkey = WebSocketTracker.getAuthPubkey(host);
    final followRedirects = ref.read(dioProvider).options.followRedirects;

    try {
      // LOGGER: HTTP logging - upload_prep
      _logHttpUploadPrep(
        host: host,
        url: url,
        nip98Pubkey: nip98Pubkey,
        contentLen: fileBytes.length,
        wsAuthPubkey: wsAuthPubkey,
        followRedirects: followRedirects,
      );

      // Make HTTP POST
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
        // LOGGER: HTTP logging - upload_result_err
        _logHttpUploadResultErr(
          host: host,
          response: response,
          msg: uploadResponse.message,
        );
        throw Exception(uploadResponse.message);
      }

      // LOGGER: HTTP logging - upload_result_ok
      _logHttpUploadResultOk(
        host: host,
        response: response,
      );

      return uploadResponse;
    } catch (error) {
      throw FileUploadException(error, url: url);
    }
  }

  // Large multipart uploader that generates its own token
  Future<UploadResponse> _uploadLargeMultipart({
    required String url,
    required MediaFile file,
    required Uint8List fileBytes,
    String? alt,
    CancelToken? cancelToken,
    EventSigner? customEventSigner,
  }) async {
    // Generate auth token with conditional 10100 attestation
    final authToken = await generateAuthorizationToken(
      ref: ref,
      url: url,
      method: 'POST',
      fileBytes: fileBytes,
      customEventSigner: customEventSigner,
    );

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

  /// Minimal helper to detect on-behalf/attestation HTTP errors
  /// Later move to a more generic helper!!!
  static bool _isOnBehalfAttestationError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode ?? 0;
      final body = e.response?.data?.toString().toLowerCase() ?? e.message?.toLowerCase() ?? '';
      return (code == 403 || code == 401) &&
          (body.contains('on-behalf') || body.contains('attestation'));
    }

    if (e is IONException) {
      final m = e.message.toLowerCase();
      final has403 = m.contains('status code of 403') || m.contains(' 403 ');

      return (has403 || m.contains(' 401 ')) &&
          (m.contains('on-behalf') || m.contains('attestation'));
    }

    // If none of the above, check the string representation
    final s = e.toString().toLowerCase();
    return s.contains('on-behalf');
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

// TODO: Remove loggers
void _logHttpUploadResultErr({
  required String host,
  required Response<dynamic> response,
  required String msg,
}) {
  final instanceHeader = response.headers.value('via') ??
      response.headers.value('x-instance') ??
      response.headers.value('cf-ray');
  final code = response.statusCode ?? 0;
  Logger.warning(
    'NOSTR.HTTP upload_result_err host=$host code=$code msg="$msg" server_instance=${instanceHeader ?? 'null'}',
  );
}

// For log purposes only
void _logHttpUploadResultOk({required String host, required Response<dynamic> response}) {
  final instanceHeader = response.headers.value('via') ??
      response.headers.value('x-instance') ??
      response.headers.value('cf-ray');
  final code = response.statusCode ?? 0;
  Logger.info(
    'NOSTR.HTTP upload_result_ok host=$host code=$code server_instance=${instanceHeader ?? 'null'}',
  );
}

// For log purposes only
void _logHttpUploadPrep({
  required String host,
  required String url,
  required String? nip98Pubkey,
  required int contentLen,
  required bool followRedirects,
  String? wsAuthPubkey,
}) {
  Logger.info(
    'NOSTR.HTTP upload_prep host=$host url=$url ws_auth_pubkey=${wsAuthPubkey ?? 'null'} nip98.pubkey=$nip98Pubkey content_len=$contentLen follow_redirects=$followRedirects',
  );
}
