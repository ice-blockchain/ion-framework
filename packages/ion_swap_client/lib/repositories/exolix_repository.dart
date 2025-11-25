import 'package:dio/dio.dart';
import 'package:ion_swap_client/repositories/api_repository.dart';

class ExolixRepository implements ApiRepository {
  ExolixRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;
}
