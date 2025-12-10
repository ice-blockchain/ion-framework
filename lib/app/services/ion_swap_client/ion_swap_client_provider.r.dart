// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
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
    ionSwapContractAddress: env.get(EnvVariable.CRYPTOCURRENCIES_ION_SWAP_CONTRACT_ADDRESS),
    iceBscTokenAddress: env.get(EnvVariable.CRYPTOCURRENCIES_ICE_BSC_TOKEN_ADDRESS),
    ionBscTokenAddress: env.get(EnvVariable.CRYPTOCURRENCIES_ION_BSC_TOKEN_ADDRESS),
    ionBridgeRouterContractAddress:
        env.get(EnvVariable.CRYPTOCURRENCIES_ION_BRIDGE_ROUTER_CONTRACT_ADDRESS),
    ionBridgeContractAddress: env.get(EnvVariable.CRYPTOCURRENCIES_ION_BRIDGE_CONTRACT_ADDRESS),
    interceptors: [
      if (logger != null) logger,
    ],
  );

  final web3client = ref.watch(web3ClientProvider);
  final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);

  final ionSwapClient = SwapControllerLocator().swapCoinsController(
    config: config,
    ionIdentityClient: ionIdentityClient,
    web3client: web3client,
  );

  return ionSwapClient;
}
