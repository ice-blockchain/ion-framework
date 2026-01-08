// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/providers/web3client_provider.r.dart';
import 'package:ion_swap_client/utils/evm_tx_builder.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trade_infrastructure_providers.r.g.dart';

@riverpod
EvmContractProviders evmContractProviders(Ref ref) {
  return EvmContractProviders();
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
