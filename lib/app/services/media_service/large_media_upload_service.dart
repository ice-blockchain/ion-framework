// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/queue.dart';

// Parallel tus upload using concatenation.
class LargeMediaUploadService {
  const LargeMediaUploadService({
    required this.dio,
    this.partialSize = 1024 * 1024,
    this.maxConcurrentPartials = 5,
    this.maxRetriesPerPartial = 3,
    this.retryBaseDelayMs = 400,
  });

  final Dio dio;

  /// Size of each tus partial (bytes).
  final int partialSize;

  /// How many partials to upload concurrently.
  final int maxConcurrentPartials;

  /// Retries for a failing PATCH of a partial.
  final int maxRetriesPerPartial;

  /// Base delay for exponential backoff (ms).
  final int retryBaseDelayMs;

  /// Parallel tus upload using concatenation.
  ///
  /// [caption] – if null, defaults to file name (legacy behavior).
  /// [cancelToken] – optional cancelation token propagated to all requests.
  Future<UploadResponse> upload({
    required String url,
    required MediaFile file,
    required String authToken,
    required Uint8List fileBytes,
    FileAlt? alt,
    String? caption,
    CancelToken? cancelToken,
  }) async {
    final filePath = file.path;
    final fileLen = fileBytes.length;
    final totalParts = (fileLen / partialSize).ceil();

    final fileName = file.name ?? file.basename;
    final fileNameB64 = base64Encode(utf8.encode(fileName));
    final captionB64 = base64Encode(utf8.encode(caption ?? fileName));

    final queue = ConcurrentTasksQueue(maxConcurrent: maxConcurrentPartials);

    final partLocations = List<String?>.filled(totalParts, null);

    final futures = <Future<void>>[];
    for (var i = 0; i < totalParts; i++) {
      final index = i;
      final start = index * partialSize;
      final endExclusive = math.min(start + partialSize, fileLen);
      final partSize = endExclusive - start;

      futures.add(
        queue.add(() async {
          final location = await _uploadSinglePartial(
            endpoint: url,
            filePath: filePath,
            byteStart: start,
            byteEndExclusive: endExclusive,
            partSize: partSize,
            authToken: authToken,
            fileNameB64: fileNameB64,
            cancelToken: cancelToken,
          );

          partLocations[index] = location;
        }),
      );
    }

    await Future.wait(futures);

    if (partLocations.any((e) => e == null)) {
      throw FileUploadException('One or more partial uploads did not complete', url: url);
    }

    final locations = partLocations.cast<String>();
    final response = await _finalizeConcatenation(
      url: url,
      partLocations: locations,
      file: file,
      authToken: authToken,
      alt: alt,
      fileNameB64: fileNameB64,
      captionB64: captionB64,
      cancelToken: cancelToken,
    );

    return response;
  }

  /// Creates a partial upload and uploads the byte range [byteStart, byteEndExclusive).
  /// Handles 409 offset correction and validates 204 + Upload-Offset responses.
  Future<String> _uploadSinglePartial({
    required String endpoint,
    required String filePath,
    required int byteStart,
    required int byteEndExclusive,
    required int partSize,
    required String authToken,
    required String fileNameB64,
    CancelToken? cancelToken,
  }) async {
    final createResponse = await dio.post<dynamic>(
      endpoint,
      options: Options(
        headers: {
          'Content-Length': '0',
          'Upload-Length': partSize.toString(),
          'Upload-Concat': 'partial',
          'Upload-Metadata': 'fileName $fileNameB64',
          ..._commonHeaders(authToken: authToken),
        },
      ),
      cancelToken: cancelToken,
    );

    if (createResponse.statusCode != 201) {
      throw FileUploadException(
        'Failed to create partial: ${createResponse.statusCode}',
        url: endpoint,
      );
    }

    final locHeader = createResponse.headers.value('location');
    if (locHeader == null) {
      throw FileUploadException('Missing Location header for partial create', url: endpoint);
    }

    final base = Uri.parse(endpoint);
    final partUrl = base.resolve(locHeader).toString();

    await _patchRange(
      uploadUrl: partUrl,
      filePath: filePath,
      bodyStart: byteStart,
      bodyLength: partSize,
      authToken: authToken,
      cancelToken: cancelToken,
    );

    return partUrl;
  }

  /// Sends (sub)range PATCHes until [bodyLength] bytes are acknowledged.
  /// Handles 204 + Upload-Offset, 409 offset correction, retries with exponential backoff.
  Future<void> _patchRange({
    required String uploadUrl,
    required String filePath,
    required int bodyStart,
    required int bodyLength,
    required String authToken,
    CancelToken? cancelToken,
  }) async {
    var attempt = 0;
    var offset = await _probeOffset(
      uploadUrl: uploadUrl,
      authToken: authToken,
      cancelToken: cancelToken,
    );

    while (offset < bodyLength) {
      final remaining = bodyLength - offset;
      final toSend = remaining;
      final streamStart = bodyStart + offset;

      final file = File(filePath);
      final stream = file.openRead(streamStart, streamStart + toSend);

      try {
        final resp = await dio.patch<dynamic>(
          uploadUrl,
          data: stream,
          options: Options(
            headers: {
              'Upload-Offset': '$offset',
              'Content-Type': 'application/offset+octet-stream',
              'Content-Length': '$toSend',
              ..._commonHeaders(authToken: authToken),
            },
            responseType: ResponseType.stream,
          ),
          cancelToken: cancelToken,
        );

        final status = resp.statusCode ?? 0;

        if (status == 204) {
          final srvOffsetStr = resp.headers.value('upload-offset');
          final srvOffset = int.tryParse(srvOffsetStr ?? '');
          if (srvOffset == null) {
            throw FileUploadException('PATCH 204 without Upload-Offset', url: uploadUrl);
          }
          if (srvOffset < offset || srvOffset > bodyLength) {
            throw FileUploadException('Server offset out of range: $srvOffset', url: uploadUrl);
          }

          offset = srvOffset;
          attempt = 0;
          continue;
        }

        if (status == 409) {
          final corr = resp.headers.value('upload-offset');
          if (corr == null) {
            throw FileUploadException('409 without Upload-Offset', url: uploadUrl);
          }
          final corrOffset = int.parse(corr);
          if (corrOffset == offset) {
            await Future<void>.delayed(const Duration(milliseconds: 150));
          }
          offset = corrOffset;
          continue;
        }

        throw FileUploadException('PATCH failed: $status', url: uploadUrl);
      } on DioException catch (error) {
        if (++attempt > maxRetriesPerPartial) rethrow;
        final backoff = _backoff(attempt);

        Logger.error(
          'PATCH error: ${error.message}; retry#$attempt in ${backoff.inMilliseconds}ms',
        );

        await Future<void>.delayed(backoff);

        offset = await _probeOffset(
          uploadUrl: uploadUrl,
          authToken: authToken,
          cancelToken: cancelToken,
        );
      }
    }
  }

  Future<int> _probeOffset({
    required String uploadUrl,
    required String authToken,
    CancelToken? cancelToken,
  }) async {
    try {
      final head = await dio.head<dynamic>(
        uploadUrl,
        options: Options(
          headers: _commonHeaders(authToken: authToken),
        ),
        cancelToken: cancelToken,
      );
      final offStr = head.headers.value('upload-offset');
      final off = int.tryParse(offStr ?? '0') ?? 0;
      return off;
    } on DioException catch (error) {
      Logger.log('HEAD probe failed (${error.message}), assuming offset=0');
      return 0;
    }
  }

  Duration _backoff(int attempt) {
    final base = retryBaseDelayMs * math.pow(2, attempt - 1);
    final jitter = math.Random().nextDouble() * 0.4 + 0.8;
    return Duration(milliseconds: (base * jitter).toInt());
  }

  Future<UploadResponse> _finalizeConcatenation({
    required String url,
    required List<String> partLocations,
    required MediaFile file,
    required String authToken,
    required String fileNameB64,
    required String captionB64,
    FileAlt? alt,
    CancelToken? cancelToken,
  }) async {
    final mimeType = file.mimeType;
    final metadata = <String>[
      'fileName $fileNameB64',
      'caption $captionB64', // legacy param preserved
      if (mimeType != null) 'contentType ${base64Encode(utf8.encode(mimeType))}',
      if (alt != null) 'alt ${base64Encode(utf8.encode(alt.toShortString()))}',
    ];

    final concatValue = 'final;${partLocations.join(' ')}';

    final resp = await dio.post<dynamic>(
      url,
      options: Options(
        headers: {
          'Upload-Concat': concatValue,
          'Upload-Metadata': metadata.join(','),
          ..._commonHeaders(authToken: authToken),
        },
      ),
      cancelToken: cancelToken,
    );

    final uploadResponse = UploadResponse.fromJson(
      json.decode(resp.data as String) as Map<String, dynamic>,
    );

    if (uploadResponse.status != 'success') {
      throw FileUploadException(uploadResponse.message, url: url);
    }

    final tags = uploadResponse.nip94Event.tags;
    for (final t in tags) {
      if (t.isNotEmpty && t.first == 'url' && t.length > 1) {
        break;
      }
    }
    return uploadResponse;
  }

  Map<String, String> _commonHeaders({
    required String authToken,
  }) {
    return {
      'Tus-Resumable': '1.0.0',
      'Authorization': authToken,
    };
  }
}
