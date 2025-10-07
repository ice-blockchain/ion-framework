// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/network_fee_type.dart';
import 'package:ion/app/features/wallets/model/transfer_result.f.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coins_service.r.g.dart';
part 'transfer_factory.dart';

@riverpod
Future<CoinsService> coinsService(Ref ref) async {
  return CoinsService(
    ref.watch(coinsRepositoryProvider),
    ref.watch(networksRepositoryProvider),
    await ref.watch(ionIdentityClientProvider.future),
  );
}

class CoinsService {
  CoinsService(
    this._coinsRepository,
    this._networksRepository,
    this._ionIdentityClient,
  );

  final CoinsRepository _coinsRepository;
  final NetworksRepository _networksRepository;
  final IONIdentityClient _ionIdentityClient;

  Stream<Iterable<CoinData>> watchCoins(Iterable<String>? coinIds) =>
      _coinsRepository.watchCoins(coinIds);

  Future<CoinData?> getCoinById(String coinId) => _coinsRepository.getCoinById(coinId);

  Future<CoinData?> getNativeCoin(NetworkData network) => _coinsRepository.getNativeCoin(network);

  Future<Iterable<CoinsGroup>> getCoinGroups({
    int? limit,
    int? offset,
    Iterable<String>? symbolGroups,
    Iterable<String>? excludeCoinIds,
  }) =>
      _coinsRepository.getCoinGroups(
        limit: limit,
        offset: offset,
        symbolGroups: symbolGroups,
        excludeCoinIds: excludeCoinIds,
      );

  Future<Iterable<CoinData>> getCoinsByFilters({
    String? symbolGroup,
    String? symbol,
    NetworkData? network,
    String? contractAddress,
  }) {
    return _coinsRepository.getCoinsByFilters(
      symbolGroups: symbolGroup != null ? [symbolGroup] : null,
      symbols: symbol != null ? [symbol] : null,
      networks: network != null ? [network.id] : null,
      contractAddresses: contractAddress != null ? [contractAddress] : null,
    );
  }

  Future<Iterable<CoinData>> getSyncedCoinsBySymbolGroup(String symbolGroup) async {
    final networks = await _networksRepository.getAllAsMap();
    return _ionIdentityClient.coins.getCoinsBySymbolGroup(symbolGroup).then(
          (result) => result
              .where((coin) => networks.containsKey(coin.network))
              .map((coin) => CoinData.fromDTO(coin, networks[coin.network]!)),
        );
  }

  Future<TransferResult> getTransfer({
    required String walletId,
    required String transferId,
  }) async {
    final result = await _ionIdentityClient.wallets.getWalletTransferRequestById(
      transferId: transferId,
      walletId: walletId,
    );

    return TransferResult.fromDTO(result);
  }

  Future<TransferResult> send({
    required double amount,
    required Wallet senderWallet,
    required String receiverAddress,
    required WalletAsset sendableAsset,
    required OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
    NetworkFeeType? feeType,
    String? memo,
  }) async {
    final transfer = _TransferFactory().create(
      receiverAddress: receiverAddress,
      amountValue: amount,
      sendableAsset: sendableAsset,
      networkFeeType: feeType,
      memo: memo,
    );
    final result = await _ionIdentityClient.wallets.makeTransfer(
      senderWallet,
      transfer,
      onVerifyIdentity,
    );

    return TransferResult.fromJson(result);
  }
}
