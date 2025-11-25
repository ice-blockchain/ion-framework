import 'package:ion_swap_client/controllers/swap_controller.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/repositories/exolix_repository.dart';
import 'package:ion_swap_client/repositories/lets_exchange_repository.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';
import 'package:ion_swap_client/service_locator/repositories/api_repository_service_locator.dart';

class SwapControllerLocator {
  factory SwapControllerLocator() {
    return _instance;
  }

  SwapControllerLocator._internal();

  static final SwapControllerLocator _instance = SwapControllerLocator._internal();

  SwapController? _swapCoinsController;

  SwapController swapCoinsController({
    required IONSwapConfig config,
  }) {
    if (_swapCoinsController != null) {
      return _swapCoinsController!;
    }

    final apiRepositoryServiceLocator = ApiRepositoryServiceLocator();
    final okxRepository = apiRepositoryServiceLocator.get<SwapOkxRepository>(config: config);
    final relayApiRepository = apiRepositoryServiceLocator.get<RelayApiRepository>(config: config);
    final exolixRepository = apiRepositoryServiceLocator.get<ExolixRepository>(config: config);
    final letsExchangeRepository = apiRepositoryServiceLocator.get<LetsExchangeRepository>(config: config);

    _swapCoinsController = SwapController(
      swapOkxRepository: okxRepository,
      relayApiRepository: relayApiRepository,
      exolixRepository: exolixRepository,
      letsExchangeRepository: letsExchangeRepository,
      chainsIdsRepository: ChainsIdsRepository(),
    );

    return _swapCoinsController!;
  }
}
