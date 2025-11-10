import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';
import 'package:ion_swap_client/service_locator/network_service_locator.dart';

class RelayServiceLocator {
  factory RelayServiceLocator() {
    return _instance;
  }

  RelayServiceLocator._internal();

  static final RelayServiceLocator _instance = RelayServiceLocator._internal();

  RelayApiRepository? _relayApiRepository;

  RelayApiRepository relayApiRepository({
    required IONSwapConfig config,
  }) {
    if (_relayApiRepository != null) {
      return _relayApiRepository!;
    }

    _relayApiRepository = RelayApiRepository(
      dio: NetworkServiceLocator().relayDio(config: config),
    );

    return _relayApiRepository!;
  }
}
