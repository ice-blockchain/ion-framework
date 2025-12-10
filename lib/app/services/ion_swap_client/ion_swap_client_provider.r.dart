// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/service_locator/swap_controller_locator.dart';
import 'package:ion_swap_client/services/swap_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_swap_client_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<SwapService> ionSwapClient(Ref ref) async {
  final env = ref.watch(envProvider.notifier);

  final logger = Logger.talkerDioLogger;

  final config = IONSwapConfig(
    okxApiKey: env.get(EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_API_KEY),
    okxSignKey: env.get(EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_SIGN_KEY),
    okxPassphrase: env.get(EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_PASSPHRASE),
    okxApiUrl: env.get(EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_API_URL),
    relayBaseUrl: env.get(EnvVariable.CRYPTOCURRENCIES_BRIDGE_RELAY_BASE_URL),
    exolixApiKey: env.get(EnvVariable.CRYPTOCURRENCIES_CEX_EXOLIX_API_KEY),
    exolixApiUrl: env.get(EnvVariable.CRYPTOCURRENCIES_CEX_EXOLIX_API_URL),
    letsExchangeApiKey: env.get(EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_KEY),
    letsExchangeApiUrl: env.get(EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_URL),
    letsExchangeAffiliateId: env.get(
      EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_AFFILIATE_ID,
    ),
    // TODO(ice-erebus): provide IONSwap contract address on BSC
    ionSwapContractAddress: "",
    // TODO(ice-erebus): provide ICE (v1) token address on BSC
    iceBscTokenAddress: '0xc335df7c25b72eec661d5aa32a7c2b7b2a1d1874',
    // TODO(ice-erebus): provide ION token address on BSC
    ionBscTokenAddress: '0x2c73996BaBF1a06c2C057177353293f7cA0907c8',
    interceptors: [
      if (logger != null) logger,
    ],
  );

  final web3client = ref.watch(web3ClientProvider);

  final ionSwapClient = SwapControllerLocator().swapCoinsController(
    config: config,
    web3client: web3client,
  );

  return ionSwapClient;
}
