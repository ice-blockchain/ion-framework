import 'package:ion_swap_client/controllers/swap_controller.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/service_locator/repositories/okx_service_locator.dart';
import 'package:ion_swap_client/service_locator/repositories/relay_service_locator.dart';

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

    _swapCoinsController = SwapController(
      swapOkxRepository: OkxServiceLocator().okxRepository(config: config),
      relayApiRepository: RelayServiceLocator().relayApiRepository(config: config),
      chainsIdsRepository: ChainsIdsRepository(),
    );

    return _swapCoinsController!;
  }
}
