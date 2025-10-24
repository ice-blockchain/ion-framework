// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
import 'package:ion/app/features/core/providers/wallets_provider.r.dart';
import 'package:ion/app/features/wallets/data/mappers/nft_mapper.dart';
import 'package:ion/app/features/wallets/data/repository/coins_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/networks_repository.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_comparator.dart';
import 'package:ion/app/features/wallets/domain/wallet_views/sync_wallet_views_coins_service.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_type.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';
import 'package:ion/app/features/wallets/model/transaction_crypto_asset.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/model/wallet_view_data.f.dart';
import 'package:ion/app/features/wallets/model/wallet_view_update.f.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/concurrency.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';

part 'create_update_wallet_view_request_builder.dart';
part 'wallet_view_parser.dart';
part 'wallet_views_live_updater.dart';
part 'wallet_views_service.r.g.dart';

@riverpod
Future<WalletViewsService> walletViewsService(Ref ref) async {
  final (
    identity,
    wallets,
    mainWallet,
    transactionsRepo,
    syncService,
  ) = await (
    ref.watch(ionIdentityClientProvider.future),
    ref.watch(walletsNotifierProvider.future),
    ref.watch(mainWalletProvider.future),
    ref.watch(transactionsRepositoryProvider.future),
    ref.watch(syncWalletViewCoinsServiceProvider.future),
  ).wait;

  final service = WalletViewsService(
    identity,
    wallets,
    mainWallet,
    ref.watch(walletViewParserProvider),
    ref.watch(networksRepositoryProvider),
    transactionsRepo,
    syncService,
    await ref.watch(walletViewsLiveUpdaterProvider.future),
  );

  ref.onDispose(service.dispose);

  return service;
}

class WalletViewsService {
  WalletViewsService(
    this._identity,
    this._userWallets,
    this._mainUserWallet,
    this._walletViewParser,
    this._networksRepository,
    this._transactionsRepository,
    this._syncWalletViewCoinsService,
    this._liveUpdater,
  );

  final List<Wallet> _userWallets;
  final Wallet? _mainUserWallet;
  final IONIdentityClient _identity;
  final WalletViewParser _walletViewParser;
  final NetworksRepository _networksRepository;
  final TransactionsRepository _transactionsRepository;
  final SyncWalletViewCoinsService _syncWalletViewCoinsService;
  final WalletViewsLiveUpdater _liveUpdater;

  final StreamController<List<WalletViewData>> _walletViewsController =
      StreamController.broadcast();

  Stream<List<WalletViewData>> get walletViews => _walletViewsController.stream;
  List<WalletViewData> _originWalletViews = [];
  List<WalletViewData> _modifiedWalletViews = [];

  List<WalletViewData> get lastEmitted => _modifiedWalletViews;

  StreamSubscription<List<WalletViewData>>? _updatesSubscription;

  Future<List<WalletViewData>> fetch() async {
    final shortViews = await _identity.wallets.getWalletViews();

    final viewsDetailsDTO = await mapWithConcurrency<ShortWalletView, WalletView>(
      shortViews,
      mapper: (e) => _fetchEntireWalletView(e.id),
    );

    final networks = await _networksRepository.getAllAsMap();
    final mainWalletViewId = viewsDetailsDTO.isEmpty
        ? '' // if there no wallet views, we haven't the main one
        : viewsDetailsDTO.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b).id;

    _originWalletViews = await viewsDetailsDTO
        .map(
          (viewDTO) => _walletViewParser.parse(
            viewDTO,
            networks,
            isMainWalletView: viewDTO.id == mainWalletViewId,
          ),
        )
        .wait
        .then((result) => result.toList());

    await _updateEmittedWalletViews(walletViews: _originWalletViews);

    return _modifiedWalletViews;
  }

  Future<void> refresh(String walletViewId) async {
    Logger.info('[WalletViewsService] Refreshing wallet view $walletViewId with pagination');
    final viewDTO = await _fetchEntireWalletView(walletViewId);
    final networks = await _networksRepository.getAllAsMap();

    final index = _originWalletViews.indexWhere((w) => w.id == walletViewId);
    if (index == -1) {
      Logger.error('Cannot refresh wallet view $walletViewId: not found in current wallet views');
      return;
    }

    final currentWalletView = _originWalletViews[index];
    final refreshedWalletView = await _walletViewParser.parse(
      viewDTO,
      networks,
      isMainWalletView: currentWalletView.isMainWalletView,
    );
    _originWalletViews[index] = refreshedWalletView;
    await _updateEmittedWalletViews(walletViews: _originWalletViews);
  }

  Future<void> _updateEmittedWalletViews({
    List<WalletViewData>? walletViews,
    bool refreshSubscriptions = true,
    bool updatePeriodicCoinsSync = true,
    bool applyCurrentFiltering = true,
  }) async {
    if (updatePeriodicCoinsSync) {
      final coins = _originWalletViews.expand((wv) => wv.coins).map((c) => c.coin).toList();
      await _syncWalletViewCoinsService.start(coins);
    }

    if (walletViews != null) {
      _modifiedWalletViews =
          applyCurrentFiltering ? await _liveUpdater.applyFiltering(walletViews) : walletViews;
    }

    _walletViewsController.add(_modifiedWalletViews);

    if (refreshSubscriptions) _refreshUpdateSubscription();
  }

  void _refreshUpdateSubscription() {
    if (_originWalletViews.isEmpty) return;

    _updatesSubscription?.cancel();
    _updatesSubscription =
        _liveUpdater.watchWalletViews(_originWalletViews).listen((updatedViews) async {
      if (_originWalletViews.isEmpty) return;

      await _updateEmittedWalletViews(
        walletViews: updatedViews,
        refreshSubscriptions: false,
        updatePeriodicCoinsSync: false,
        applyCurrentFiltering: false, // Already filtered by live updater
      );
    });
  }

  Future<WalletViewData> create(String name) async {
    final request = _CreateUpdateRequestBuilder().build(name: name);
    final networks = await _networksRepository.getAllAsMap();
    final newWalletView = await _identity.wallets.createWalletView(request).then(
          (viewDTO) => _walletViewParser.parse(viewDTO, networks, isMainWalletView: false),
        );

    _originWalletViews = [..._originWalletViews, newWalletView];
    await _updateEmittedWalletViews(walletViews: _originWalletViews);

    return newWalletView;
  }

  Future<WalletViewData> update({
    required WalletViewData walletView,
    String? updatedName,
    List<CoinData>? updatedCoinsList,
  }) async {
    final networks = await _networksRepository.getAllAsMap();
    final request = _CreateUpdateRequestBuilder().build(
      name: updatedName,
      walletView: walletView,
      coinsList: updatedCoinsList,
      userWallets: _userWallets,
      mainUserWallet: _mainUserWallet,
    );

    final updatedWalletView = await _identity.wallets.updateWalletView(walletView.id, request).then(
          (viewDTO) => _walletViewParser.parse(
            viewDTO,
            networks,
            isMainWalletView: walletView.isMainWalletView,
          ),
        );

    final index = _originWalletViews.indexWhere((w) => w.id == walletView.id);

    if (index != -1) {
      _originWalletViews[index] = updatedWalletView;
    } else {
      _originWalletViews.add(updatedWalletView);
    }

    await _updateEmittedWalletViews(walletViews: _originWalletViews);

    return updatedWalletView;
  }

  Future<void> delete({required String walletViewId}) async {
    await _identity.wallets.deleteWalletView(walletViewId);

    unawaited(
      _transactionsRepository.remove(
        walletViewIds: [walletViewId],
      ),
    );

    _originWalletViews = _originWalletViews.where((view) => view.id != walletViewId).toList();

    await _updateEmittedWalletViews(walletViews: _originWalletViews);
  }

  void dispose() {
    _walletViewsController.close();
    _updatesSubscription?.cancel();
  }

  // Fetches all pages for a wallet view and returns a WalletView with merged NFTs.
  Future<WalletView> _fetchEntireWalletView(String walletViewId) async {
    final mergedNftsByKey = <String, WalletNft>{};
    WalletView? lastView;

    String? paginationToken;
    do {
      final page = await _getWalletViewPageWithRetry(
        walletViewId,
        paginationToken: paginationToken,
      );
      lastView = page.walletView;

      final nfts = page.walletView.nfts ?? const <WalletNft>[];
      for (final nft in nfts) {
        final key = '${nft.network}|${nft.contract}|${nft.tokenId}';
        mergedNftsByKey[key] = nft;
      }

      final rawToken = page.nextPageToken;
      paginationToken = (rawToken == null || rawToken.trim().isEmpty) ? null : rawToken;
    } while (paginationToken != null);

    return lastView.copyWith(nfts: mergedNftsByKey.values.toList());
  }

  // Performs a single page fetch with retry policy; returns partial NFTs collected so far on final failure.
  Future<WalletViewResponse> _getWalletViewPageWithRetry(
    String walletViewId, {
    String? paginationToken,
  }) async {
    return withRetry<WalletViewResponse>(
      ({error}) async {
        return _identity.wallets
            .getWalletView(
          walletViewId,
          paginationToken: paginationToken,
        )
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException(
              'Getting wallet view page timed out after 15 seconds',
            );
          },
        );
      },
      maxRetries: 3,
      initialDelay: const Duration(milliseconds: 200),
      maxDelay: const Duration(milliseconds: 1500),
      multiplier: 2,
      onRetry: (error) async {
        Logger.error(
          error ?? 'Unknown error',
          message:
              '[WalletViewsService] getWalletView page failed; retrying walletViewId=$walletViewId paginationToken=${paginationToken ?? 'null'}',
        );
      },
    );
  }
}
