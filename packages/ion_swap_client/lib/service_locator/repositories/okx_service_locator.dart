import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/repositories/swap_okx_repository.dart';
import 'package:ion_swap_client/service_locator/network_service_locator.dart';

class OkxServiceLocator {
  factory OkxServiceLocator() {
    return _instance;
  }

  OkxServiceLocator._internal();

  static final OkxServiceLocator _instance = OkxServiceLocator._internal();

  SwapOkxRepository? _swapOkxRepository;

  SwapOkxRepository okxRepository({
    required IONSwapConfig config,
  }) {
    if (_swapOkxRepository != null) {
      return _swapOkxRepository!;
    }

    _swapOkxRepository = SwapOkxRepository(
      dio: NetworkServiceLocator().okxDio(config: config),
    );

    return _swapOkxRepository!;
  }
}
