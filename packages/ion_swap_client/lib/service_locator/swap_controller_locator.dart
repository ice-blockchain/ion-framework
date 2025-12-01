// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/service_locator/repositories/api_repository_service_locator.dart';
import 'package:ion_swap_client/services/swap_service.dart';

class SwapControllerLocator {
  factory SwapControllerLocator() {
    return _instance;
  }

  SwapControllerLocator._internal();

  static final SwapControllerLocator _instance = SwapControllerLocator._internal();

  SwapService? _swapCoinsController;

  SwapService swapCoinsController({
    required IONSwapConfig config,
  }) {
    if (_swapCoinsController != null) {
      return _swapCoinsController!;
    }

    final apiRepositoryServiceLocator = ApiRepositoryServiceLocator();
    final okxRepository = apiRepositoryServiceLocator.getSwapOkxRepository(config: config);
    final relayApiRepository = apiRepositoryServiceLocator.getRelayApiRepository(config: config);
    final exolixRepository = apiRepositoryServiceLocator.getExolixRepository(config: config);
    final letsExchangeRepository = apiRepositoryServiceLocator.getLetsExchangeRepository(config: config);

    _swapCoinsController = SwapService(
      swapOkxRepository: okxRepository,
      relayApiRepository: relayApiRepository,
      exolixRepository: exolixRepository,
      letsExchangeRepository: letsExchangeRepository,
      chainsIdsRepository: ChainsIdsRepository(),
      config: config,
    );

    return _swapCoinsController!;
  }
}
