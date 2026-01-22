import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class IonHttpFileService extends FileService {
  IonHttpFileService({
    int concurrentFetches = 10,
  }) : _concurrentFetches = concurrentFetches;

  final int _concurrentFetches;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final dio = Dio();

    final response = await dio
        .get<ResponseBody>(
          url,
          options: Options(
            headers: headers,
            responseType: ResponseType.stream,
            receiveTimeout: const Duration(seconds: 1),
            sendTimeout: const Duration(seconds: 1),
          ),
        )
        .timeout(const Duration(seconds: 1));

    final stream = response.data?.stream ?? const Stream<List<int>>.empty();

    final headerMap = <String, String>{};
    response.headers.forEach((name, values) {
      if (values.isNotEmpty) {
        headerMap[name] = values.join(', ');
      }
    });

    final streamedResponse = http.StreamedResponse(
      stream,
      response.statusCode ?? 200,
      contentLength: int.tryParse(response.headers.value('content-length') ?? ''),
      headers: headerMap,
      isRedirect: response.isRedirect,
      reasonPhrase: response.statusMessage,
    );

    return HttpGetResponse(streamedResponse);
  }

  @override
  int get concurrentFetches => _concurrentFetches;
}
