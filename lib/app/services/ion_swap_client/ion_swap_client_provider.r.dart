// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/web3client_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/models/okx_fee_address.m.dart';
import 'package:ion_swap_client/service_locator/swap_controller_locator.dart';
import 'package:ion_swap_client/services/swap_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_swap_client_provider.r.g.dart';

@Riverpod(keepAlive: true)
IONSwapConfig ionSwapConfig(Ref ref) {
  final env = ref.watch(envProvider.notifier);
  final logger = Logger.talkerDioLogger;

  return IONSwapConfig(
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
    ionJrpcUrl: env.get(EnvVariable.CRYPTOCURRENCIES_ION_JRPC_URL),
    interceptors: [
      if (logger != null) logger,
    ],
    defaultSwapPercentFee: env.get(EnvVariable.DEFAULT_SWAP_PERCENT_FEE),
    relayEvmFeeAddress: env.get(EnvVariable.RELAY_SWAP_FEE_ADDRESS),
    okxFeeAddress: OkxFeeAddress(
      avalanceAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_AVALANCE),
      arbitrumAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_ARBITRUM),
      optimistAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_OPTIMIST),
      polygonAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_POLYGON),
      solAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_SOL),
      baseAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_BASE),
      tonAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_TON),
      tronAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_TRON),
      ethAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_ETH),
      bnbAddress: env.get(EnvVariable.OKX_SWAP_FEE_ADDRESS_BNB),
    ),
  );
}

@Riverpod(keepAlive: true)
Future<SwapService> ionSwapClient(Ref ref) async {
  final config = ref.watch(ionSwapConfigProvider);
  final web3client = ref.watch(web3ClientProvider);
  final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);

  final ionSwapClient = SwapControllerLocator().swapCoinsController(
    config: config,
    ionIdentityClient: ionIdentityClient,
    web3client: web3client,
  );

  return ionSwapClient;
}
