import 'package:dio/dio.dart';

class RelayApiRepository {
  RelayApiRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<void> getQuote() async {
    final response = await _dio.post<dynamic>(
      '/quote',
    );
  }
}
