import 'package:dio/dio.dart';
import 'package:ion_swap_client/repositories/api_repository.dart';

// TODO(ice-erebus): rewrite this repository
class RelayApiRepository implements ApiRepository {
  RelayApiRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

  Future<void> getQuote() async {}
}
