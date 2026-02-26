// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/wallet_views_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_identity_client/ion_identity.dart' as ion;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_assets_token_import_sync_service.r.g.dart';

@Riverpod(keepAlive: true)
Future<WalletAssetsTokenImportSyncService> walletAssetsTokenImportSyncService(Ref ref) async {
  return WalletAssetsTokenImportSyncService(
    coinsRepository: ref.watch(coinsRepositoryProvider),
    ionIdentityClient: await ref.watch(ionIdentityClientProvider.future),
    networksRepository: ref.watch(networksRepositoryProvider),
    userWallets: await ref.watch(walletsNotifierProvider.future),
    walletViewsService: await ref.watch(walletViewsServiceProvider.future),
  );
}

class WalletAssetsTokenImportSyncService {
  WalletAssetsTokenImportSyncService({
    required CoinsRepository coinsRepository,
    required ion.IONIdentityClient ionIdentityClient,
    required NetworksRepository networksRepository,
    required List<ion.Wallet> userWallets,
    required WalletViewsService walletViewsService,
  })  : _coinsRepository = coinsRepository,
        _ionIdentityClient = ionIdentityClient,
        _networksRepository = networksRepository,
        _userWallets = userWallets,
        _walletViewsService = walletViewsService;

  final CoinsRepository _coinsRepository;
  final ion.IONIdentityClient _ionIdentityClient;
  final NetworksRepository _networksRepository;
  final List<ion.Wallet> _userWallets;
  final WalletViewsService _walletViewsService;

  Future<void>? _activeSync;

  Future<void> syncMissingTokens() {
    final activeSync = _activeSync;
    if (activeSync != null) {
      Logger.info('[AutoImport] Sync skipped: already in progress');
      return activeSync;
    }

    final future = _syncMissingTokens();
    _activeSync = future;
    return future.whenComplete(() {
      _activeSync = null;
    });
  }

  Future<void> _syncMissingTokens() async {
    if (_userWallets.isEmpty) {
      Logger.info('[AutoImport] Sync skipped: no wallets');
      return;
    }

    Logger.info('[AutoImport] Sync started for ${_userWallets.length} wallet(s)');

    final networksById = await _networksRepository.getAllAsMap();
    var walletViews = await _loadWalletViews();
    final processedKeys = <String>{};

    for (final wallet in _userWallets) {
      final network = networksById[wallet.network];
      if (network == null) {
        Logger.warning(
          '[AutoImport] Skip wallet ${wallet.id}: network ${wallet.network} not found',
        );
        continue;
      }

      try {
        final walletAssets = await _ionIdentityClient.wallets.getWalletAssets(wallet.id);

        Logger.info(
          '[AutoImport] Scanning wallet ${wallet.id} (${wallet.network}), '
          'assets=${walletAssets.assets.length}',
        );

        for (final asset in walletAssets.assets) {
          final candidate = asset.mapOrNull(
            erc20: (value) => (
              contract: value.contract,
              symbol: value.symbol,
              kind: value.kind,
              balance: value.balance,
            ),
          );

          if (candidate == null) {
            continue;
          }

          final contract = candidate.contract?.trim();
          if (contract == null || contract.isEmpty) {
            continue;
          }

          if (!_hasPositiveRawBalance(candidate.balance)) {
            Logger.info(
              '[AutoImport] Skip zero-balance token '
              'walletId=${wallet.id} network=${wallet.network} '
              'symbol=${candidate.symbol} contract=$contract',
            );
            continue;
          }

          final dedupKey = '${wallet.id}|${wallet.network}|${contract.toLowerCase()}';
          if (!processedKeys.add(dedupKey)) {
            continue;
          }

          Logger.info(
            '[AutoImport] Candidate ${candidate.kind} ${candidate.symbol} on ${wallet.network} '
            'contract=$contract walletId=${wallet.id}',
          );

          final existingCoin = await _findCoinByNetworkAndContract(
            networkId: wallet.network,
            contractAddress: contract,
          );

          final coin = existingCoin ??
              await _importCoin(
                contractAddress: contract,
                network: network,
              );

          if (coin == null) {
            continue;
          }

          final updatedWalletViews = await _attachCoinToWalletViews(
            walletId: wallet.id,
            coin: coin,
            walletViews: walletViews,
          );

          if (updatedWalletViews != null) {
            walletViews = updatedWalletViews;
          }
        }
      } catch (error) {
        Logger.error(
          error,
          message:
              '[AutoImport] Wallet scan failed walletId=${wallet.id} network=${wallet.network}',
        );
      }
    }

    Logger.info('[AutoImport] Sync completed');
  }

  Future<List<WalletViewData>> _loadWalletViews() async {
    if (_walletViewsService.lastEmitted.isNotEmpty) {
      return _walletViewsService.lastEmitted;
    }

    Logger.info('[AutoImport] Loading wallet views (walletViewsService.fetch)');
    return _walletViewsService.fetch();
  }

  Future<CoinData?> _findCoinByNetworkAndContract({
    required String networkId,
    required String contractAddress,
  }) async {
    final lowerCaseContract = contractAddress.toLowerCase();
    final contractAddresses = <String>{contractAddress, lowerCaseContract};

    final coin = await _coinsRepository.getCoinsByFilters(
      networks: [networkId],
      contractAddresses: contractAddresses,
    ).then((coins) => coins.firstOrNull);

    if (coin != null) {
      Logger.info(
        '[AutoImport] Coin already exists coinId=${coin.id} '
        'network=$networkId contract=${coin.contractAddress}',
      );
    }

    return coin;
  }

  Future<CoinData?> _importCoin({
    required String contractAddress,
    required NetworkData network,
  }) async {
    try {
      final dto = await _ionIdentityClient.coins.getCoinData(
        contractAddress: contractAddress,
        network: network.id,
      );
      final coin = CoinData.fromDTO(dto, network);

      if (!coin.isValid) {
        Logger.warning(
          '[AutoImport] Invalid imported coin skipped '
          'network=${network.id} contract=$contractAddress coinId=${coin.id}',
        );
        return null;
      }

      await _coinsRepository.updateCoins([coin.toDB()]);

      Logger.info(
        '[AutoImport] Imported coin coinId=${coin.id} network=${network.id} '
        'contract=${coin.contractAddress} symbol=${coin.abbreviation}',
      );

      return coin;
    } catch (error) {
      Logger.error(
        error,
        message: '[AutoImport] Coin import failed network=${network.id} contract=$contractAddress',
      );
      return null;
    }
  }

  Future<List<WalletViewData>?> _attachCoinToWalletViews({
    required String walletId,
    required CoinData coin,
    required List<WalletViewData> walletViews,
  }) async {
    var updatedWalletViews = walletViews;
    var hasChanges = false;

    for (var index = 0; index < updatedWalletViews.length; index++) {
      final walletView = updatedWalletViews[index];
      final walletViewCoins = walletView.coinGroups.expand((group) => group.coins).toList();

      final containsWallet = walletViewCoins.any((walletCoin) => walletCoin.walletId == walletId);
      if (!containsWallet) {
        continue;
      }

      final alreadyAttached = walletViewCoins.any((walletCoin) {
        final sameCoinId = walletCoin.coin.id == coin.id;
        final sameContract = walletCoin.coin.network.id == coin.network.id &&
            walletCoin.coin.contractAddress.toLowerCase() == coin.contractAddress.toLowerCase() &&
            coin.contractAddress.isNotEmpty;
        return sameCoinId || sameContract;
      });

      if (alreadyAttached) {
        Logger.info(
          '[AutoImport] Coin already attached walletViewId=${walletView.id} '
          'walletId=$walletId coinId=${coin.id}',
        );
        continue;
      }

      final updatedCoinsList = walletViewCoins.map((walletCoin) => walletCoin.coin).toList()
        ..add(coin);

      try {
        final updatedWalletView = await _walletViewsService.update(
          walletView: walletView,
          updatedCoinsList: updatedCoinsList,
        );

        updatedWalletViews = [...updatedWalletViews]..[index] = updatedWalletView;
        hasChanges = true;

        Logger.info(
          '[AutoImport] Attached coin to walletView '
          'walletViewId=${walletView.id} walletId=$walletId coinId=${coin.id}',
        );
      } catch (error) {
        Logger.error(
          error,
          message:
              '[AutoImport] Attach failed walletViewId=${walletView.id} walletId=$walletId coinId=${coin.id}',
        );
      }
    }

    return hasChanges ? updatedWalletViews : null;
  }

  bool _hasPositiveRawBalance(String rawBalance) {
    final parsed = BigInt.tryParse(rawBalance.trim());
    return parsed != null && parsed > BigInt.zero;
  }
}
