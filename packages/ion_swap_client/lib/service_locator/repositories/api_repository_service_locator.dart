import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/repositories/api_repository.dart';
import 'package:ion_swap_client/repositories/exolix_repository.dart';
import 'package:ion_swap_client/repositories/lets_exchange_repository.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';
import 'package:ion_swap_client/service_locator/network_service_locator.dart';

class ApiRepositoryServiceLocator {
  factory ApiRepositoryServiceLocator() {
    return _instance;
  }

  ApiRepositoryServiceLocator._internal({
    required NetworkServiceLocator networkServiceLocator,
  }) : _networkServiceLocator = networkServiceLocator;

  static final ApiRepositoryServiceLocator _instance = ApiRepositoryServiceLocator._internal(
    networkServiceLocator: NetworkServiceLocator(),
  );

  final NetworkServiceLocator _networkServiceLocator;

  static final Map<Type, ApiRepository> _cache = {};

  T get<T extends ApiRepository>({
    required IONSwapConfig config,
  }) {
    if (_cache[T] != null) {
      return _cache[T]! as T;
    }

    final repository = switch (T) {
      ExolixRepository => ExolixRepository(dio: _networkServiceLocator.exolixDio(config: config)),
      LetsExchangeRepository => LetsExchangeRepository(dio: _networkServiceLocator.letsExchangeDio(config: config)),
      RelayApiRepository => RelayApiRepository(dio: _networkServiceLocator.relayDio(config: config)),
      SwapOkxRepository => SwapOkxRepository(dio: _networkServiceLocator.okxDio(config: config)),
      _ => throw UnimplementedError('Repository $T is not implemented'),
    };

    _cache[T] = repository;

    return repository as T;
  }
}
