// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message_service.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/features/wallets/data/repository/transactions_repository.m.dart';
import 'package:ion/app/features/wallets/domain/coins/coins_service.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/send_transaction_to_relay_service.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/transfer_exception_factory.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/model/send_asset_form_data.f.dart';
import 'package:ion/app/features/wallets/model/transaction_details.f.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/app/features/wallets/model/transfer_result.f.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/providers/synced_coins_by_symbol_group_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:ion/app/utils/retry.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_coins_notifier_provider.r.g.dart';

@riverpod
class SendCoinsNotifier extends _$SendCoinsNotifier {
  static const _formName = 'SendCoins';
  static const _maxRetries = 5;
  static const _initialRetryDelay = Duration(seconds: 1);

  @override
  FutureOr<TransactionDetails?> build() {
    return null;
  }

  Future<void> send(
    OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity, [
    SendAssetFormData? sendAssetFormData,
  ]) async {
    if (state.isLoading) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final form = sendAssetFormData ?? ref.read(sendAssetFormControllerProvider);

      final coinAssetData = _extractCoinAssetData(form!);
      final (senderWallet, sendableAsset, selectedOption) =
          _validateFormComponents(form, coinAssetData);

      final walletView = await ref.read(currentWalletViewDataProvider.future);

      var result = await _executeCoinTransfer(
        coinAssetData: coinAssetData,
        senderWallet: senderWallet,
        sendableAsset: sendableAsset,
        form: form,
        onVerifyIdentity: onVerifyIdentity,
      );

      result = await _waitForTransactionCompletion(senderWallet.id, result);

      final nativeCoin = await ref
          .read(coinsServiceProvider.future)
          .then((service) => service.getNativeCoin(form.network!));

      final nativeTokenTotalBalance =
          walletView.coins.firstWhereOrNull((coin) => coin.coin.id == nativeCoin?.id);

      final isTransferringNativeToken = selectedOption.coin.native;
      final transferNativeTokenAmount = isTransferringNativeToken ? coinAssetData.amount : 0.0;

      _validateTransactionResult(
        result: result,
        coin: selectedOption.coin,
        coinAssetData: coinAssetData,
        transferNativeTokenAmount: transferNativeTokenAmount,
        nativeTokenTotalBalance: nativeTokenTotalBalance?.amount,
      );

      final details = TransactionDetails(
        id: result.id,
        walletViewId: walletView.id,
        txHash: result.txHash!,
        network: form.network!,
        status: result.status,
        type: TransactionType.send,
        dateRequested: result.dateRequested,
        dateConfirmed: result.dateConfirmed,
        dateBroadcasted: result.dateBroadcasted,
        assetData: coinAssetData.copyWith(
          rawAmount: result.requestBody['amount'].toString(),
        ),
        nativeCoin: nativeCoin,
        walletViewName: form.walletView!.name,
        senderAddress: senderWallet.address,
        receiverAddress: form.receiverAddress,
        participantPubkey: form.contactPubkey,
        networkFeeOption: form.selectedNetworkFeeOption,
        memo: result.requestBody['memo']?.toString(),
      );

      try {
        await _saveTransaction(
          details: details,
          transferResult: result,
          sendableAsset: sendableAsset,
          coinAssetData: coinAssetData,
          requestEntity: form.request,
          senderAddress: senderWallet.address,
          receiverAddress: form.receiverAddress,
        );
      } on Exception catch (e, stacktrace) {
        Logger.error('Failed to send event $e', stackTrace: stacktrace);
      }

      unawaited(
        ref.read(syncedCoinsBySymbolGroupNotifierProvider.notifier).refresh(
          symbolGroups: [coinAssetData.coinsGroup.symbolGroup],
        ),
      );

      Logger.info('Transaction was successful. Hash: ${result.txHash}');

      return details;
    });

    if (state.hasError) {
      final error = state.error!;

      // Capture to Sentry the next exceptions
      // - Unexpected ones (not IONException)
      // - Unexpected blockchain errors with reason (FailedToSendCryptoAssetsException)
      if ((error is! IONException && error is! PasskeyCancelledException) ||
          error is FailedToSendCryptoAssetsException) {
        await SentryService.logException(
          error,
          stackTrace: state.stackTrace,
          tag: 'send_coins_failure',
        );
      }
      Logger.error(error, stackTrace: state.stackTrace);
    }
  }

  CoinAssetToSendData _extractCoinAssetData(SendAssetFormData form) {
    if (form.assetData is! CoinAssetToSendData) {
      final error = FormException('Asset data must be CoinAssetToSendData', formName: _formName);
      Logger.error(error, message: 'Cannot send coins: asset data is not a coin asset');
      throw error;
    }
    return form.assetData as CoinAssetToSendData;
  }

  (
    Wallet senderWallet,
    WalletAsset sendableAsset,
    CoinInWalletData selectedOption,
  ) _validateFormComponents(
    SendAssetFormData form,
    CoinAssetToSendData coinAssetData,
  ) {
    final senderWallet = form.senderWallet;
    final sendableAsset = coinAssetData.associatedAssetWithSelectedOption;
    final selectedOption = coinAssetData.selectedOption;

    if (senderWallet == null) {
      final error = FormException('Sender wallet is required', formName: _formName);
      Logger.error(error, message: 'Cannot send coins: senderWallet is missing');
      throw error;
    }

    if (sendableAsset == null) {
      final error = FormException('Sendable asset is required', formName: _formName);
      Logger.error(error, message: 'Cannot send coins: sendableAsset is missing');
      throw error;
    }

    if (selectedOption == null) {
      final error = FormException('Selected option is required', formName: _formName);
      Logger.error(error, message: 'Cannot send coins: selectedOption is missing');
      throw error;
    }

    return (senderWallet, sendableAsset, selectedOption);
  }

  Future<TransferResult> _executeCoinTransfer({
    required CoinAssetToSendData coinAssetData,
    required Wallet senderWallet,
    required WalletAsset sendableAsset,
    required SendAssetFormData form,
    required OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
  }) async {
    final coinsService = await ref.read(coinsServiceProvider.future);

    return coinsService.send(
      amount: coinAssetData.amount,
      senderWallet: senderWallet,
      sendableAsset: sendableAsset,
      onVerifyIdentity: onVerifyIdentity,
      receiverAddress: form.receiverAddress,
      feeType: form.selectedNetworkFeeOption?.type,
      memo: form.memo,
    );
  }

  Future<TransferResult> _waitForTransactionCompletion(
    String walletId,
    TransferResult result,
  ) async {
    final coinsService = await ref.read(coinsServiceProvider.future);

    if (!_isRetryableStatus(result.status)) {
      return result;
    }

    // Transaction is still processing, wait for completion
    return withRetry<TransferResult>(
      ({Object? error}) async {
        final response = await coinsService.getTransfer(
          walletId: walletId,
          transferId: result.id,
        );

        if (_isRetryableStatus(response.status)) {
          throw InappropriateTransferStatusException();
        }

        return response;
      },
      maxRetries: _maxRetries,
      initialDelay: _initialRetryDelay,
      retryWhen: (result) => result is InappropriateTransferStatusException,
    );
  }

  bool _isRetryableStatus(TransactionStatus status) =>
      status == TransactionStatus.pending || status == TransactionStatus.executing;

  void _validateTransactionResult({
    required CoinData coin,
    required TransferResult result,
    required double transferNativeTokenAmount,
    required CoinAssetToSendData coinAssetData,
    double? nativeTokenTotalBalance,
  }) {
    if (result.status == TransactionStatus.rejected || result.status == TransactionStatus.failed) {
      throw TransferExceptionFactory.create(
        reason: result.reason,
        coin: coin,
        nativeTokenTransferAmount: transferNativeTokenAmount,
        nativeTokenTotalBalance: nativeTokenTotalBalance,
      );
    }
  }

  Future<void> _saveTransaction({
    required WalletAsset sendableAsset,
    required TransactionDetails details,
    required TransferResult transferResult,
    required CoinAssetToSendData coinAssetData,
    required FundsRequestEntity? requestEntity,
    required String? senderAddress,
    required String? receiverAddress,
  }) async {
    final transactionsRepository = await ref.read(transactionsRepositoryProvider.future);
    // Save transaction into DB
    await transactionsRepository.saveTransactionDetails(details);

    if (details.participantPubkey == null || senderAddress == null || receiverAddress == null) {
      return;
    }

    // Send transaction to the relay
    final receiverDelegation = await ref.read(
      userDelegationProvider(details.participantPubkey!).future,
    );
    final currentUserDelegation = await ref.read(currentUserDelegationProvider.future);
    final currentUserPubkey = ref.read(currentPubkeySelectorProvider) ?? '';

    final entityData = WalletAssetData(
      networkId: details.network.id,
      assetClass: sendableAsset.kind,
      assetAddress: coinAssetData.selectedOption!.coin.contractAddress,
      pubkey: details.participantPubkey,
      walletAddress: details.receiverAddress,
      content: WalletAssetContent(
        amount: transferResult.requestBody['amount'] as String?,
        amountUsd: coinAssetData.amountUSD.toString(),
        txHash: details.txHash,
        txUrl: details.transactionExplorerUrl,
        from: senderAddress,
        to: receiverAddress,
        assetId: coinAssetData.selectedOption!.coin.id,
      ),
    );

    final senderPubkeys = (
      masterPubkey: currentUserPubkey,
      devicePubkeys: currentUserDelegation?.data.delegates.map((e) => e.pubkey).toList() ?? [],
    );
    final receiverPubkeys = (
      masterPubkey: details.participantPubkey!,
      devicePubkeys: receiverDelegation?.data.delegates.map((e) => e.pubkey).toList() ?? [],
    );

    final sendToRelayService = await ref.read(sendTransactionToRelayServiceProvider.future);
    final event = await sendToRelayService.sendTransactionEntity(
      createEventMessage: (devicePubkey, masterPubkey) => entityData.toEventMessage(
        devicePubkey: devicePubkey,
        masterPubkey: masterPubkey,
        requestEntity: requestEntity,
      ),
      senderPubkeys: senderPubkeys,
      receiverPubkeys: receiverPubkeys,
    );

    final eventReference = ImmutableEventReference(
      eventId: event.id,
      masterPubkey: currentUserPubkey,
      kind: event.kind,
    );
    final content = eventReference.encode();
    final tag = eventReference.toTag();
    final paymentSentTag = [
      ReplaceablePrivateDirectMessageData.paymentSentTagName,
      jsonEncode(event.jsonPayload),
    ];

    final chatService = await ref.read(sendChatMessageServiceProvider.future);
    await chatService.send(
      kind: event.kind,
      receiverPubkey: details.participantPubkey!,
      content: content,
      tags: [tag, paymentSentTag],
    );

    // Update the transaction with the eventId from the relay
    await transactionsRepository.updateTransaction(
      txHash: details.txHash,
      walletViewId: details.walletViewId,
      eventId: event.id,
    );
  }
}
