// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_swap_client/controllers/swap_controller.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/service_locator/swap_controller_locator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_swap_client_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<SwapController> ionSwapClient(Ref ref) async {
  final env = ref.watch(envProvider.notifier);

  final logger = Logger.talkerDioLogger;

  final config = IONSwapConfig(
    okxApiKey: env.get(EnvVariable.OKX_API_KEY),
    okxSignKey: env.get(EnvVariable.OKX_SIGN_KEY),
    okxPassphrase: env.get(EnvVariable.OKX_PASSPHRASE),
    okxApiUrl: env.get(EnvVariable.OKX_API_URL),
    relayBaseUrl: env.get(EnvVariable.RELAY_BASE_URL),
    exolixApiKey: env.get(EnvVariable.EXOLIX_API_KEY),
    exolixApiUrl: env.get(EnvVariable.EXOLIX_API_URL),
    letsExchangeApiKey: env.get(EnvVariable.LETS_EXCHANGE_API_KEY),
    letsExchangeApiUrl: env.get(EnvVariable.LETS_EXCHANGE_API_URL),
    interceptors: [
      if (logger != null) logger,
    ],
  );

  final ionSwapClient = SwapControllerLocator().swapCoinsController(
    config: config,
  );

  return ionSwapClient;
}
