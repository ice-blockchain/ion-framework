// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/extract_user_id/extract_user_id_service.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_clients/user_action_signer_service_locator.dart';
import 'package:ion_identity_client/src/core/service_locator/ion_identity_service_locator.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';
import 'package:ion_identity_client/src/wallets/ion_identity_wallets.dart';
import 'package:ion_identity_client/src/wallets/services/create_wallet/create_wallet_service.dart';
import 'package:ion_identity_client/src/wallets/services/create_wallet/data_sources/create_wallet_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/generate_signature/data_sources/generate_signature_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/generate_signature/generate_signature_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_assets/data_sources/get_wallet_assets_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_assets/get_wallet_assets_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_history/data_sources/get_wallet_history_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_history/get_wallet_history_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_nfts/data_sources/get_wallet_nfts_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_nfts/get_wallet_nfts_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_transfer_requests/data_sources/get_wallet_transfer_requests_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_transfer_requests/get_wallet_transfer_requests_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallets/data_sources/get_wallets_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallets/get_wallets_service.dart';
import 'package:ion_identity_client/src/wallets/services/make_transfer/data_sources/make_transfer_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/make_transfer/make_transfer_service.dart';
import 'package:ion_identity_client/src/wallets/services/sign_and_broadcast/data_sources/sign_and_broadcast_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/sign_and_broadcast/sign_and_broadcast_service.dart';
import 'package:ion_identity_client/src/wallets/services/wallet_views/data_sources/wallet_views_data_source.dart';
import 'package:ion_identity_client/src/wallets/services/wallet_views/wallet_views_service.dart';

class WalletsClientServiceLocator {
  factory WalletsClientServiceLocator() {
    return _instance;
  }

  WalletsClientServiceLocator._internal();

  static final WalletsClientServiceLocator _instance = WalletsClientServiceLocator._internal();

  IONIdentityWallets wallets({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return IONIdentityWallets(
      username: username,
      createWalletService: createWallet(
        username: username,
        config: config,
        identitySigner: identitySigner,
      ),
      getWalletsService: getWallets(username: username, config: config),
      getWalletAssetsService: getWalletAssets(username: username, config: config),
      getWalletNftsService: getWalletNfts(username: username, config: config),
      getWalletHistoryService: getWalletHistory(username: username, config: config),
      getWalletTransferRequestsService: getWalletTransferRequests(
        username: username,
        config: config,
      ),
      generateSignatureService: generateSignature(
        username: username,
        config: config,
        identitySigner: identitySigner,
      ),
      walletViewsService: walletViews(
        username: username,
        config: config,
      ),
      extractUserIdService: ExtractUserIdService(
        tokenStorage: IONIdentityServiceLocator.tokenStorage(),
      ),
      makeTransferService: makeTransferService(
        username: username,
        config: config,
        signer: identitySigner,
      ),
      signAndBroadcastService: signAndBroadcastService(
        username: username,
        config: config,
        signer: identitySigner,
      ),
    );
  }

  CreateWalletService createWallet({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return CreateWalletService(
      username: username,
      dataSource: const CreateWalletDataSource(),
      userActionSigner: UserActionSignerServiceLocator().userActionSigner(
        config: config,
        identitySigner: identitySigner,
      ),
    );
  }

  GetWalletsService getWallets({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetWalletsService(
      username,
      GetWalletsDataSource(
        IONIdentityServiceLocator.networkClient(config: config),
        IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  GetWalletAssetsService getWalletAssets({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetWalletAssetsService(
      username,
      GetWalletAssetsDataSource(
        IONIdentityServiceLocator.networkClient(config: config),
        IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  GetWalletNftsService getWalletNfts({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetWalletNftsService(
      GetWalletNftsDataSource(
        username,
        IONIdentityServiceLocator.networkClient(config: config),
        IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  GetWalletHistoryService getWalletHistory({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetWalletHistoryService(
      username,
      GetWalletHistoryDataSource(
        IONIdentityServiceLocator.networkClient(config: config),
        IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  GetWalletTransferRequestsService getWalletTransferRequests({
    required String username,
    required IONIdentityConfig config,
  }) {
    return GetWalletTransferRequestsService(
      username,
      GetWalletTransferRequestsDataSource(
        IONIdentityServiceLocator.networkClient(config: config),
        IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  GenerateSignatureService generateSignature({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner identitySigner,
  }) {
    return GenerateSignatureService(
      username: username,
      dataSource: const GenerateSignatureDataSource(),
      userActionSigner: UserActionSignerServiceLocator().userActionSigner(
        config: config,
        identitySigner: identitySigner,
      ),
    );
  }

  WalletViewsService walletViews({
    required String username,
    required IONIdentityConfig config,
  }) {
    return WalletViewsService(
      username,
      WalletViewsDataSource(
        IONIdentityServiceLocator.networkClient(config: config),
        IONIdentityServiceLocator.tokenStorage(),
      ),
    );
  }

  MakeTransferService makeTransferService({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner signer,
  }) {
    return MakeTransferService(
      makeTransferDataSource: MakeTransferDataSource(username),
      userActionSigner: UserActionSignerServiceLocator().userActionSigner(
        config: config,
        identitySigner: signer,
      ),
    );
  }

  SignAndBroadcastService signAndBroadcastService({
    required String username,
    required IONIdentityConfig config,
    required IdentitySigner signer,
  }) {
    return SignAndBroadcastService(
      signAndBroadcastDataSource: SignAndBroadcastDataSource(username),
    );
  }
}
