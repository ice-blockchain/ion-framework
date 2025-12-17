// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/ion_swap_config.dart';
import 'package:ion_swap_client/repositories/chains_ids_repository.dart';
import 'package:ion_swap_client/service_locator/repositories/api_repository_service_locator.dart';
import 'package:ion_swap_client/services/bridge_service.dart';
import 'package:ion_swap_client/services/cex_service.dart';
import 'package:ion_swap_client/services/dex_service.dart';
import 'package:ion_swap_client/services/ion_bsc_to_ion_bridge_service.dart';
import 'package:ion_swap_client/services/ion_swap_service.dart';
import 'package:ion_swap_client/services/ion_to_bsc_bridge_service.dart';
import 'package:ion_swap_client/services/swap_service.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:ion_swap_client/utils/ion_identity_transaction_api.dart';
import 'package:web3dart/web3dart.dart';

class SwapControllerLocator {
  factory SwapControllerLocator() {
    return _instance;
  }

  SwapControllerLocator._internal();

  static final SwapControllerLocator _instance = SwapControllerLocator._internal();

  SwapService? _swapCoinsController;

  SwapService swapCoinsController({
    required IONSwapConfig config,
    required IONIdentityClient ionIdentityClient,
    required Web3Client web3client,
  }) {
    if (_swapCoinsController != null) {
      return _swapCoinsController!;
    }

    final apiRepositoryServiceLocator = ApiRepositoryServiceLocator();
    final okxRepository = apiRepositoryServiceLocator.getSwapOkxRepository(config: config);
    final relayApiRepository = apiRepositoryServiceLocator.getRelayApiRepository(config: config);
    final exolixRepository = apiRepositoryServiceLocator.getExolixRepository(config: config);
    final letsExchangeRepository =
        apiRepositoryServiceLocator.getLetsExchangeRepository(config: config);
    final evmTxBuilder = EvmTxBuilder(
      contracts: EvmContractProviders(),
      web3Client: web3client,
    );
    final ionIdentityTransactionApi = IonIdentityTransactionApi(
      ionIdentityClient: ionIdentityClient,
    );

    _swapCoinsController = SwapService(
      ionBscToIonBridgeService: IonBscToIonBridgeService(
        config: config,
        web3client: web3client,
        evmTxBuilder: evmTxBuilder,
        ionIdentityClient: ionIdentityTransactionApi,
      ),
      ionToBscBridgeService: IonToBscBridgeService(
        config: config,
        ionIdentityClient: ionIdentityTransactionApi,
      ),
      ionSwapService: IonSwapService(
        ionIdentityClient: IonIdentityTransactionApi(
          ionIdentityClient: ionIdentityClient,
        ),
        config: config,
        web3client: web3client,
        evmTxBuilder: evmTxBuilder,
      ),
      okxService: DexService(
        swapOkxRepository: okxRepository,
        chainsIdsRepository: ChainsIdsRepository(),
      ),
      cexService: CexService(
        letsExchangeRepository: letsExchangeRepository,
        exolixRepository: exolixRepository,
        config: config,
      ),
      bridgeService: BridgeService(
        relayApiRepository: relayApiRepository,
      ),
    );

    return _swapCoinsController!;
  }
}
