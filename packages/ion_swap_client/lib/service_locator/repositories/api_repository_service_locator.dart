import 'package:dio/dio.dart';
import 'package:ion_swap_client/repositories/api_repository.dart';
import 'package:ion_swap_client/repositories/exolix_repository.dart';
import 'package:ion_swap_client/repositories/lets_exchange_repository.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';

class ApiRepositoryServiceLocator<T extends ApiRepository> {
  factory ApiRepositoryServiceLocator() {
    return _instance as ApiRepositoryServiceLocator<T>;
  }

  ApiRepositoryServiceLocator._internal();

  static final ApiRepositoryServiceLocator _instance = ApiRepositoryServiceLocator._internal();

  T? _repository;

  T repository({
    required Dio dio,
  }) {
    if (_repository != null) {
      return _repository!;
    }

    _repository = _repositoryBuilder(
      dio: dio,
    );

    return _repository!;
  }

  T _repositoryBuilder({
    required Dio dio,
  }) {
    return switch (T) {
      ExolixRepository => ExolixRepository(dio: dio) as T,
      LetsExchangeRepository => LetsExchangeRepository(dio: dio) as T,
      RelayApiRepository => RelayApiRepository(dio: dio) as T,
      SwapOkxRepository => SwapOkxRepository(dio: dio) as T,
      _ => throw UnimplementedError('Repository $T is not implemented'),
    };
  }
}
