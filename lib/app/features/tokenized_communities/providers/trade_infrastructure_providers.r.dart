// SPDX-License-Identifier: ice License 1.0

import 'package:http/http.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web3dart/web3dart.dart';

part 'trade_infrastructure_providers.r.g.dart';

@riverpod
EvmContractProviders evmContractProviders(Ref ref) {
  return EvmContractProviders();
}

@riverpod
Web3Client web3Client(Ref ref) {
  // Using the BNB Testnet RPC as requested
  final rpcUrl =
      ref.watch(envProvider.notifier).get<String>(EnvVariable.CRYPTOCURRENCIES_BSC_RPC_URL);
  final httpClient = Client();
  return Web3Client(rpcUrl, httpClient);
}

@riverpod
EvmTxBuilder evmTxBuilder(Ref ref) {
  final contracts = ref.watch(evmContractProvidersProvider);
  final web3Client = ref.watch(web3ClientProvider);
  return EvmTxBuilder(
    contracts: contracts,
    web3Client: web3Client,
  );
}
