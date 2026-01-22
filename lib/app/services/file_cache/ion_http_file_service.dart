import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class IonHttpFileService extends FileService {
  IonHttpFileService({
    int concurrentFetches = 10,
    Duration timeout = const Duration(seconds: 10),
  })  : _concurrentFetches = concurrentFetches,
        _timeout = timeout,
        _dio = Dio();

  final int _concurrentFetches;
  final Duration _timeout;
  final Dio _dio;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _dio
          .get<ResponseBody>(
            url,
            options: Options(
              headers: headers,
              responseType: ResponseType.stream,
              receiveTimeout: _timeout,
              sendTimeout: _timeout,
            ),
          )
          .timeout(_timeout);

      final stream = response.data?.stream;
      if (stream == null) {
        throw HttpException(
          'No response data',
          uri: Uri.parse(url),
        );
      }

      final headerMap = _convertHeaders(response.headers);

      final streamedResponse = http.StreamedResponse(
        stream,
        response.statusCode ?? 200,
        contentLength: int.tryParse(response.headers.value('content-length') ?? ''),
        headers: headerMap,
        isRedirect: response.isRedirect,
        reasonPhrase: response.statusMessage,
      );

      return HttpGetResponse(streamedResponse);
    } on DioException catch (e) {
      throw HttpException(
        e.message ?? 'Network error',
        uri: Uri.parse(url),
      );
    }
  }

  Map<String, String> _convertHeaders(Headers headers) {
    final headerMap = <String, String>{};
    headers.forEach((name, values) {
      if (values.isNotEmpty) {
        headerMap[name] = values.join(', ');
      }
    });
    return headerMap;
  }

  @override
  int get concurrentFetches => _concurrentFetches;
}
