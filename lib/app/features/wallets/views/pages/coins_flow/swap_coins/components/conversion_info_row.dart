// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/exceptions/insufficient_balance_exception.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_swap_client/exceptions/ion_bridge_exception.dart';
import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';
import 'package:ion_swap_client/exceptions/lets_exchange_exceptions.dart';
import 'package:ion_swap_client/exceptions/okx_exceptions.dart';
import 'package:ion_swap_client/exceptions/relay_exception.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';

class ConversionInfoRow extends HookConsumerWidget {
  const ConversionInfoRow({
    required this.sellCoin,
    required this.buyCoin,
    super.key,
  });

  final CoinsGroup sellCoin;
  final CoinsGroup buyCoin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyles = context.theme.appTextThemes;
    final swapCoinsController = ref.watch(swapCoinsControllerProvider);
    final isLoading = swapCoinsController.isQuoteLoading;
    final isError = swapCoinsController.isQuoteError;
    final quoteError = swapCoinsController.quoteError;
    final swapQuoteInfo = swapCoinsController.swapQuoteInfo;

    if (isLoading) {
      return const _LoadingState();
    }

    if (isError) {
      return _ErrorState(
        quoteError: quoteError,
      );
    }

    if (swapQuoteInfo == null) {
      return SizedBox(
        height: 72.0.s,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 25.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '1 ${sellCoin.name} = ${swapQuoteInfo.priceForSellTokenInBuyToken.formatMax6} ${buyCoin.name}',
              style: textStyles.body2.copyWith(),
            ),
          ),
          Text(
            swapQuoteInfo.type == SwapQuoteInfoType.bridge ? 'Bridge' : 'Cex + Dex',
            style: textStyles.body2.copyWith(),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 25.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBox(
            width: 120.0.s,
            height: 16.0.s,
          ),
          Row(
            spacing: 4.0.s,
            children: [
              SkeletonBox(
                width: 76.0.s,
                height: 16.0.s,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.quoteError,
  });

  final Exception? quoteError;

  String _getErrorMessage(
    BuildContext context,
  ) {
    return switch (quoteError) {
      RelayException() => _getRelayErrorMessage(
          context,
          quoteError! as RelayException,
        ),
      OkxException() => _getOkxErrorMessage(
          context,
          quoteError! as OkxException,
        ),
      LetsExchangeException() => _getLetsExchangeErrorMessage(
          context,
          quoteError! as LetsExchangeException,
        ),
      InsufficientBalanceException() => context.i18n.error_swap_82000,
      final AmountBelowMinimumException ex =>
        context.i18n.error_swap_amount_below_min(ex.minAmount, ex.symbol),
      _ => context.i18n.error_getting_swap_quote,
    };
  }

  String _getRelayErrorMessage(BuildContext context, RelayException quoteError) {
    return switch (quoteError) {
      const CoinPairNotFoundException() => context.i18n.error_swap_coin_pair_not_found,
      const AmountTooLowException() => context.i18n.error_swap_amount_too_low,
      const ChainDisabledException() => context.i18n.error_swap_chain_disabled,
      const ExtraTxsNotSupportedException() => context.i18n.error_swap_extra_txs_not_supported,
      const ForbiddenException() => context.i18n.error_swap_forbidden,
      const InsufficientFundsException() => context.i18n.error_swap_insufficient_funds,
      const InsufficientLiquidityException() => context.i18n.error_swap_insufficient_liquidity,
      const InvalidAddressException() => context.i18n.error_swap_invalid_address,
      const InvalidExtraTxsException() => context.i18n.error_swap_invalid_extra_txs,
      const InvalidGasLimitForDepositSpecifiedTxsException() =>
        context.i18n.error_swap_invalid_gas_limit_for_deposit_specified_txs,
      const InvalidInputCurrencyException() => context.i18n.error_swap_invalid_input_currency,
      const InvalidOutputCurrencyException() => context.i18n.error_swap_invalid_output_currency,
      const InvalidSlippageToleranceException() =>
        context.i18n.error_swap_invalid_slippage_tolerance,
      const NoInternalSwapRoutesFoundException() =>
        context.i18n.error_swap_no_internal_swap_routes_found,
      const NoQuotesException() => context.i18n.error_swap_no_quotes,
      const NoSwapRoutesFoundException() => context.i18n.error_swap_no_swap_routes_found,
      const RouteTemporarilyRestrictedException() =>
        context.i18n.error_swap_route_temporarily_restricted,
      const SanctionedCurrencyException() => context.i18n.error_swap_sanctioned_currency,
      const SanctionedWalletAddressException() => context.i18n.error_swap_sanctioned_wallet_address,
      const SwapImpactTooHighException() => context.i18n.error_swap_swap_impact_too_high,
      const UnauthorizedException() => context.i18n.error_swap_unauthorized,
      const UnsupportedChainException() => context.i18n.error_swap_unsupported_chain,
      const UnsupportedCurrencyException() => context.i18n.error_swap_unsupported_currency,
      const UnsupportedExecutionTypeException() =>
        context.i18n.error_swap_unsupported_execution_type,
      const UnsupportedRouteException() => context.i18n.error_swap_unsupported_route,
      const UserRecipientMismatchException() => context.i18n.error_swap_user_recipient_mismatch,
      _ => context.i18n.error_getting_swap_quote,
    };
  }

  String _getOkxErrorMessage(BuildContext context, OkxException quoteError) {
    return switch (quoteError) {
      OkxRepeatedRequestException() => context.i18n.error_swap_80000,
      OkxCallDataExceedsLimitException() => context.i18n.error_swap_80001,
      OkxTokenObjectCountLimitException() => context.i18n.error_swap_80002,
      OkxNativeTokenObjectCountLimitException() => context.i18n.error_swap_80003,
      OkxSuiObjectQueryTimeoutException() => context.i18n.error_swap_80004,
      OkxInsufficientSuiObjectsException() => context.i18n.error_swap_80005,
      OkxInsufficientLiquidityException() => context.i18n.error_swap_82000,
      OkxInvalidReferrerWalletAddressException() => context.i18n.error_swap_82003,
      OkxBelowMinimumQuantityException() => context.i18n.error_swap_82102,
      OkxExceedsMaximumQuantityException() => context.i18n.error_swap_82103,
      OkxTokenNotSupportedException() => context.i18n.error_swap_82104,
      OkxQuoteRouteDifferenceException() => context.i18n.error_swap_82112,
      OkxCallDataExceedsMaximumException() => context.i18n.error_swap_82116,
      OkxChainNoAuthorizationRequiredException() => context.i18n.error_swap_82130,
      OkxFourMemeCommissionSplitNotSupportedException() => context.i18n.error_swap_82004,
      OkxAspectaCommissionSplitNotSupportedException() => context.i18n.error_swap_82005,
      _ => context.i18n.error_getting_swap_quote,
    };
  }

  String _getLetsExchangeErrorMessage(BuildContext context, LetsExchangeException quoteError) {
    return switch (quoteError) {
      LetsExchangePairUnavailableException() => context.i18n.error_swap_pair_unavailable,
      _ => context.i18n.error_getting_swap_quote,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;

    if (quoteError is IonSwapCoinPairNotFoundException) {
      return SizedBox(
        height: 72.0.s,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 25.0.s,
      ),
      child: Row(
        children: [
          Assets.svg.iconBlockInformation.icon(
            color: colors.tertiaryText,
            size: 16.0.s,
          ),
          SizedBox(width: 5.0.s),
          Expanded(
            child: Text(
              _getErrorMessage(
                context,
              ),
              style: textStyles.body2.copyWith(),
            ),
          ),
        ],
      ),
    );
  }
}
