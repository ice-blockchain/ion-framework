// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/src/wallets/services/wallet_views/data_sources/wallet_views_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/wallet_views/models/create_update_wallet_view_request.f.dart';
import 'package:ion_identity_client/src/wallets/services/wallet_views/models/short_wallet_view.f.dart';
import 'package:ion_identity_client/src/wallets/services/wallet_views/models/wallet_view.f.dart';

class WalletViewsService {
  const WalletViewsService(
    this.username,
    this._walletViewsDataSource,
  );

  final String username;
  final WalletViewsDataSource _walletViewsDataSource;

  Future<List<ShortWalletView>> getWalletViews(String userId) {
    return _walletViewsDataSource.getWalletViews(username, userId);
  }

  Future<WalletView> createWalletView(
    CreateUpdateWalletViewRequest request,
    String userId,
  ) {
    return _walletViewsDataSource.createWalletView(userId, username, request);
  }

  Future<WalletViewResponse> getWalletView({
    required String userId,
    required String walletViewId,
    int? limit,
    String? paginationToken,
  }) {
    return _walletViewsDataSource.getWalletView(
      userId: userId,
      username: username,
      walletViewId: walletViewId,
      limit: limit,
      paginationToken: paginationToken,
    );
  }

  Future<WalletView> updateWalletView(
    String userId,
    String walletViewId,
    CreateUpdateWalletViewRequest request,
  ) {
    return _walletViewsDataSource.updateWalletView(
      userId: userId,
      request: request,
      username: username,
      walletViewId: walletViewId,
    );
  }

  Future<void> deleteWalletView(String walletViewId, String userId) {
    return _walletViewsDataSource.deleteWalletView(
      username,
      userId,
      walletViewId,
    );
  }
}
