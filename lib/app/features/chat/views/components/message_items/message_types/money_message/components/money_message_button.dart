// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/views/pages/error_modal.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';
import 'package:ion/app/features/wallets/providers/coins_provider.r.dart';
import 'package:ion/app/features/wallets/providers/funds_request_delete_notifier.r.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class RequestedMoneyMessageButton extends StatelessWidget {
  const RequestedMoneyMessageButton({
    required this.isMe,
    required this.eventId,
    required this.isPaid,
    required this.isDeleted,
    required this.eventMessage,
    required this.request,
    super.key,
  });

  final bool isMe;
  final String eventId;
  final bool isPaid;
  final bool isDeleted;
  final FundsRequestEntity request;
  final EventMessage eventMessage;

  static Size get _defaultMinimumSize => Size(150.0.s, 32.0.s);

  @override
  Widget build(BuildContext context) {
    return switch (isMe) {
      true => _CancelMoneyRequestButton(
          eventMessage: eventMessage,
          isPaid: isPaid,
          isDeleted: isDeleted,
        ),
      false => _SendMoneyButton(
          eventId: eventId,
          request: request,
          isPaid: isPaid,
          isDeleted: isDeleted,
        ),
    };
  }
}

class _CancelMoneyRequestButton extends ConsumerWidget {
  const _CancelMoneyRequestButton({
    required this.eventMessage,
    required this.isPaid,
    required this.isDeleted,
  });

  final EventMessage eventMessage;
  final bool isPaid;
  final bool isDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(fundsRequestDeleteNotifierProvider(eventMessage: eventMessage)).isLoading;

    final isDisabled = isLoading || isPaid || isDeleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.2 : 1.0,
      child: Button.compact(
        type: ButtonType.outlined,
        backgroundColor: context.theme.appColors.tertiaryBackground,
        minimumSize: RequestedMoneyMessageButton._defaultMinimumSize,
        disabled: isDisabled,
        label: isLoading
            ? const IONLoadingIndicator(type: IndicatorType.dark)
            : Text(
                isDeleted ? context.i18n.chat_money_message_cancelled : context.i18n.button_cancel,
                style: context.theme.appTextThemes.caption2.copyWith(
                  color: context.theme.appColors.primaryText,
                ),
              ),
        onPressed: () {
          ref
              .read(fundsRequestDeleteNotifierProvider(eventMessage: eventMessage).notifier)
              .deleteFundsRequest();
        },
      ),
    );
  }
}

class _SendMoneyButton extends ConsumerWidget {
  const _SendMoneyButton({
    required this.eventId,
    required this.request,
    required this.isPaid,
    required this.isDeleted,
  });

  final String eventId;
  final FundsRequestEntity? request;
  final bool isPaid;
  final bool isDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sendAssetFormControllerProvider);

    final disabled = isPaid || isDeleted;

    return Button.compact(
      type: disabled ? ButtonType.disabled : ButtonType.outlined,
      backgroundColor:
          disabled ? context.theme.appColors.sheetLine : context.theme.appColors.darkBlue,
      minimumSize: RequestedMoneyMessageButton._defaultMinimumSize,
      label: Text(
        context.i18n.button_send,
        style: context.theme.appTextThemes.caption2.copyWith(
          color: context.theme.appColors.onPrimaryAccent,
        ),
      ),
      disabled: disabled,
      onPressed: () async => _handleSendMoney(context, ref),
    );
  }

  Future<void> _handleSendMoney(BuildContext context, WidgetRef ref) async {
    if (request == null) return;
    const formName = 'send_coins_form_chat';

    try {
      ref.invalidate(sendAssetFormControllerProvider);
      final sendAssetFormController = ref.read(sendAssetFormControllerProvider.notifier);

      // Extract request data
      final receiverAddress = request?.data.content.to;
      final senderAddress = request?.data.content.from;
      final amount = request?.data.content.amount;
      final networkId = request?.data.networkId ?? '';
      final assetId = request?.data.content.assetId ?? '';
      final receiverPubkey = request?.data.pubkey;

      // Get required data from providers
      final network = await ref.read(networkByIdProvider(networkId).future);
      if (network == null) {
        throw FormException('Network not found', formName: formName);
      }

      final walletView = await ref.read(walletViewByAddressProvider(senderAddress ?? '').future);
      if (walletView == null) {
        throw FormException('Wallet not found', formName: formName);
      }

      final coinsInWalletView = await ref.read(coinsInWalletViewProvider(walletView.id).future);
      if (coinsInWalletView.isEmpty) {
        throw FormException('No coins found in wallet', formName: formName);
      }

      final coinGroup = coinsInWalletView.firstWhereOrNull(
        (cg) => cg.coins.any((c) => c.coin.id == assetId),
      );
      if (coinGroup == null) {
        throw FormException('Coin group not found', formName: formName);
      }

      await sendAssetFormController.setCoin(coinGroup, walletView);

      final maxAmount = coinGroup.totalAmount;

      sendAssetFormController
        ..setRequest(request!)
        ..setContact(receiverPubkey, isContactPreselected: true)
        ..setReceiverAddress(receiverAddress ?? '');

      await sendAssetFormController.setNetwork(network);

      sendAssetFormController
        ..setCoinsAmount(amount ?? '')
        ..exceedsMaxAmount = (parseAmount(amount) ?? 0) > maxAmount;

      if (!context.mounted) return;

      await SendCoinsFormChatRoute().push<void>(context);
    } catch (e) {
      if (context.mounted) {
        showErrorModal(context, e);
      }
    }
  }
}

class ViewTransactionButton extends ConsumerWidget {
  const ViewTransactionButton({
    required this.transactionData,
    super.key,
  });

  final TransactionData transactionData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button.compact(
      backgroundColor: context.theme.appColors.darkBlue,
      tintColor: context.theme.appColors.darkBlue,
      minimumSize: RequestedMoneyMessageButton._defaultMinimumSize,
      label: Text(
        context.i18n.chat_money_received_button,
        style: context.theme.appTextThemes.caption2.copyWith(
          color: context.theme.appColors.onPrimaryAccent,
        ),
      ),
      onPressed: () async {
        final assetId = transactionData.cryptoAsset.mapOrNull(coin: (value) => value.coin.id);
        if (assetId == null) {
          return;
        }

        final coinData = await ref.read(coinByIdProvider(assetId).future);
        if (coinData == null) {
          return;
        }

        if (!context.mounted) {
          return;
        }
        unawaited(
          CoinTransactionDetailsChatRoute(
            walletViewId: transactionData.walletViewId,
            txHash: transactionData.txHash,
          ).push<void>(context),
        );
      },
    );
  }
}
