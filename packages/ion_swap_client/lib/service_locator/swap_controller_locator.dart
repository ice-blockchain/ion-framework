import 'package:ion_swap_client/controllers/swap_controller.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/repositories/exolix_repository.dart';
import 'package:ion_swap_client/repositories/lets_exchange_repository.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';
import 'package:ion_swap_client/service_locator/network_service_locator.dart';
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

    final networkServiceLocator = NetworkServiceLocator();
    final okxRepository = ApiRepositoryServiceLocator<SwapOkxRepository>().repository(
      dio: networkServiceLocator.okxDio(config: config),
    );
    final relayApiRepository = ApiRepositoryServiceLocator<RelayApiRepository>().repository(
      dio: networkServiceLocator.relayDio(config: config),
    );
    final exolixRepository = ApiRepositoryServiceLocator<ExolixRepository>().repository(
      dio: networkServiceLocator.exolixDio(config: config),
    );
    final letsExchangeRepository = ApiRepositoryServiceLocator<LetsExchangeRepository>().repository(
      dio: networkServiceLocator.letsExchangeDio(config: config),
    );

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
