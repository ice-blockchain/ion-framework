// SPDX-License-Identifier: ice License 1.0

import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/extract_user_id/extract_user_id_service.dart';
import 'package:ion_identity_client/src/wallets/services/create_wallet/create_wallet_service.dart';
import 'package:ion_identity_client/src/wallets/services/generate_signature/generate_signature_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_fees/get_fees_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_assets/get_wallet_assets_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_history/get_wallet_history_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_nfts/get_wallet_nfts_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallet_transfer_requests/get_wallet_transfer_requests_service.dart';
import 'package:ion_identity_client/src/wallets/services/get_wallets/get_wallets_service.dart';
import 'package:ion_identity_client/src/wallets/services/make_transfer/make_transfer_service.dart';
import 'package:ion_identity_client/src/wallets/services/sign_and_broadcast/sign_and_broadcast_service.dart';
import 'package:ion_identity_client/src/wallets/services/sign_and_broadcast/sign_service.dart';
import 'package:ion_identity_client/src/wallets/services/wallet_views/wallet_views_service.dart';

/// A class that handles operations related to user wallets, such as listing the wallets
/// associated with a specific user.
class IONIdentityWallets {
  /// Creates an instance of [IONIdentityWallets] with the provided [username], [config],
  /// [dataSource], and [signer].
  ///
  /// - [username]: The username of the user whose wallets are being managed.
  /// - [config]: The client configuration containing necessary identifiers.
  /// - [dataSource]: The data source responsible for API interactions related to wallets.
  /// - [signer]: The passkey signer used for handling cryptographic operations, if needed.
  IONIdentityWallets({
    required this.username,
    required CreateWalletService createWalletService,
    required GetWalletsService getWalletsService,
    required GetWalletAssetsService getWalletAssetsService,
    required GetWalletNftsService getWalletNftsService,
    required GetWalletHistoryService getWalletHistoryService,
    required GetWalletTransferRequestsService getWalletTransferRequestsService,
    required GenerateSignatureService generateSignatureService,
    required WalletViewsService walletViewsService,
    required ExtractUserIdService extractUserIdService,
    required MakeTransferService makeTransferService,
    required GetFeesService getFeesService,
    required SignAndBroadcastService signAndBroadcastService,
    required SignService signService,
  })  : _createWalletService = createWalletService,
        _getWalletsService = getWalletsService,
        _getWalletAssetsService = getWalletAssetsService,
        _getWalletNftsService = getWalletNftsService,
        _getWalletHistoryService = getWalletHistoryService,
        _getWalletTransferRequestsService = getWalletTransferRequestsService,
        _generateSignatureService = generateSignatureService,
        _walletViewsService = walletViewsService,
        _extractUserIdService = extractUserIdService,
        _makeTransferService = makeTransferService,
        _signAndBroadcastService = signAndBroadcastService,
        _getFeesService = getFeesService,
        _signService = signService;

  final String username;

  final CreateWalletService _createWalletService;
  final GetWalletsService _getWalletsService;
  final GetWalletAssetsService _getWalletAssetsService;
  final GetWalletNftsService _getWalletNftsService;
  final GetWalletHistoryService _getWalletHistoryService;
  final GetWalletTransferRequestsService _getWalletTransferRequestsService;
  final GenerateSignatureService _generateSignatureService;
  final WalletViewsService _walletViewsService;
  final ExtractUserIdService _extractUserIdService;
  final MakeTransferService _makeTransferService;
  final SignAndBroadcastService _signAndBroadcastService;
  final GetFeesService _getFeesService;
  final SignService _signService;

  Future<Wallet> createWallet({
    required String network,
    required String walletViewId,
    required OnVerifyIdentity<Wallet> onVerifyIdentity,
  }) =>
      _createWalletService.createWallet(
        network: network,
        walletViewId: walletViewId,
        onVerifyIdentity: onVerifyIdentity,
      );

  /// Lists the wallets associated with the current user by making an API request.
  ///
  /// Returns a [Future] that resolves to a [List<Wallet>] containing the user's wallets.
  /// If an error occurs during the API request or processing, it will be thrown as an exception.
  Future<List<Wallet>> getWallets() => _getWalletsService.getWallets();

  Future<WalletAssets> getWalletAssets(String walletId) =>
      _getWalletAssetsService.getWalletAssets(walletId);

  Future<WalletNfts> getWalletNfts(String walletId) =>
      _getWalletNftsService.getWalletNfts(walletId);

  Future<WalletHistory> getWalletHistory(
    String walletId, {
    String? pageToken,
    int? pageSize,
  }) =>
      _getWalletHistoryService.getWalletHistory(walletId, pageToken: pageToken, pageSize: pageSize);

  Future<WalletTransferRequests> getWalletTransferRequests(
    String walletId, {
    String? pageToken,
    int? pageSize,
  }) =>
      _getWalletTransferRequestsService.getWalletTransferRequests(
        walletId,
        pageToken: pageToken,
        pageSize: pageSize,
      );

  Future<WalletTransferRequest> getWalletTransferRequestById({
    required String walletId,
    required String transferId,
  }) =>
      _getWalletTransferRequestsService.getWalletTransferRequestById(
        walletId: walletId,
        transferId: transferId,
      );

  Future<GenerateSignatureResponse> generateMessageSignatureWithPasskey(
    String walletId,
    String message,
  ) =>
      _generateSignatureService.generateMessageSignatureWithPasskey(
        walletId: walletId,
        message: message,
      );

  Future<GenerateSignatureResponse> generateMessageSignatureWithPassword(
    String walletId,
    String message,
    String password,
  ) =>
      _generateSignatureService.generateMessageSignatureWithPassword(
        walletId: walletId,
        message: message,
        password: password,
      );

  Future<GenerateSignatureResponse> generateHashSignature({
    required String walletId,
    required String hash,
    required OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity,
  }) async {
    return onVerifyIdentity(
      onPasswordFlow: ({required String password}) {
        return _generateSignatureService.generateHashSignatureWithPassword(
          walletId: walletId,
          hash: hash,
          password: password,
        );
      },
      onPasskeyFlow: () {
        return _generateSignatureService.generateHashSignatureWithPasskey(
          walletId: walletId,
          hash: hash,
        );
      },
      onBiometricsFlow: ({required String localisedReason, required String localisedCancel}) {
        return _generateSignatureService.generateHashSignatureWithBiometrics(
          walletId: walletId,
          hash: hash,
          localisedReason: localisedReason,
          localisedCancel: localisedCancel,
        );
      },
    );
  }

  Future<List<ShortWalletView>> getWalletViews() {
    final userId = _extractUserIdService.extractUserId(username: username);
    return _walletViewsService.getWalletViews(userId);
  }

  Future<WalletView> createWalletView(CreateUpdateWalletViewRequest request) {
    final userId = _extractUserIdService.extractUserId(username: username);
    return _walletViewsService.createWalletView(request, userId);
  }

  Future<WalletViewResponse> getWalletView(
    String walletViewId, {
    int? limit,
    String? paginationToken,
  }) {
    final userId = _extractUserIdService.extractUserId(username: username);
    return _walletViewsService.getWalletView(
      userId: userId,
      walletViewId: walletViewId,
      limit: limit,
      paginationToken: paginationToken,
    );
  }

  Future<WalletView> updateWalletView(
    String walletViewId,
    CreateUpdateWalletViewRequest request,
  ) {
    final userId = _extractUserIdService.extractUserId(username: username);
    return _walletViewsService.updateWalletView(userId, walletViewId, request);
  }

  Future<void> deleteWalletView(String walletViewId) {
    final userId = _extractUserIdService.extractUserId(username: username);
    return _walletViewsService.deleteWalletView(walletViewId, userId);
  }

  Future<Map<String, dynamic>> makeTransfer(
    Wallet wallet,
    Transfer request,
    OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
  ) =>
      _makeTransferService.makeTransfer(
        wallet: wallet,
        request: request,
        onVerifyIdentity: onVerifyIdentity,
      );

  /// Signs and broadcasts an EVM transaction or user operations.
  ///
  /// Supports both standard transactions (hex or JSON format) and fee-sponsored
  /// user operations (ERC-4337 style).
  ///
  /// - [wallet]: The wallet to use for signing and broadcasting
  /// - [request]: The broadcast request (transaction or user operations)
  /// - [signer]: The signer for user action authentication
  ///
  /// Returns a [Future] that resolves to a [Map<String, dynamic>] containing the transaction result.
  Future<Map<String, dynamic>> signAndBroadcast(
    Wallet wallet,
    EvmBroadcastRequest request,
    UserActionSignerNew signer,
  ) =>
      _signAndBroadcastService.signAndBroadcast(
        wallet: wallet,
        request: request,
        signer: signer,
      );

  Future<Map<String, dynamic>> getFees(List<String> networks) => _getFeesService.getFees(networks);
  
  Future<Map<String, dynamic>> sign(
    Wallet wallet,
    String message,
    UserActionSignerNew signer,
  ) =>
      _signService.sign(
        wallet: wallet,
        message: message,
        signer: signer,
      );
}
