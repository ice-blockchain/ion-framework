// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/ion_swap_config.dart';
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

  ExolixRepository? _exolixRepository;
  LetsExchangeRepository? _letsExchangeRepository;
  RelayApiRepository? _relayApiRepository;
  SwapOkxRepository? _swapOkxRepository;

  ExolixRepository getExolixRepository({
    required IONSwapConfig config,
  }) {
    if (_exolixRepository != null) {
      return _exolixRepository!;
    }

    _exolixRepository = ExolixRepository(
      dio: _networkServiceLocator.exolixDio(
        config: config,
      ),
    );

    return _exolixRepository!;
  }

  LetsExchangeRepository getLetsExchangeRepository({
    required IONSwapConfig config,
  }) {
    if (_letsExchangeRepository != null) {
      return _letsExchangeRepository!;
    }

    _letsExchangeRepository = LetsExchangeRepository(
      dio: _networkServiceLocator.letsExchangeDio(
        config: config,
      ),
    );

    return _letsExchangeRepository!;
  }

  RelayApiRepository getRelayApiRepository({
    required IONSwapConfig config,
  }) {
    if (_relayApiRepository != null) {
      return _relayApiRepository!;
    }

    _relayApiRepository = RelayApiRepository();

    return _relayApiRepository!;
  }

  SwapOkxRepository getSwapOkxRepository({
    required IONSwapConfig config,
  }) {
    if (_swapOkxRepository != null) {
      return _swapOkxRepository!;
    }

    _swapOkxRepository = SwapOkxRepository(
      dio: _networkServiceLocator.okxDio(
        config: config,
      ),
    );

    return _swapOkxRepository!;
  }
}
