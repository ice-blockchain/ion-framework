// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';

class RelayException extends IonSwapException {
  const RelayException([super.message]);

  factory RelayException.fromErrorCode(String errorCode) {
    return switch (errorCode) {
      'COIN_PAIR_NOT_FOUND' => const CoinPairNotFoundException(),
      'AMOUNT_TOO_LOW' => const AmountTooLowException(),
      'CHAIN_DISABLED' => const ChainDisabledException(),
      'EXTRA_TXS_NOT_SUPPORTED' => const ExtraTxsNotSupportedException(),
      'FORBIDDEN' => const ForbiddenException(),
      'INSUFFICIENT_FUNDS' => const InsufficientFundsException(),
      'INSUFFICIENT_LIQUIDITY' => const InsufficientLiquidityException(),
      'INVALID_ADDRESS' => const InvalidAddressException(),
      'INVALID_EXTRA_TXS' => const InvalidExtraTxsException(),
      'INVALID_GAS_LIMIT_FOR_DEPOSIT_SPECIFIED_TXS' =>
        const InvalidGasLimitForDepositSpecifiedTxsException(),
      'INVALID_INPUT_CURRENCY' => const InvalidInputCurrencyException(),
      'INVALID_OUTPUT_CURRENCY' => const InvalidOutputCurrencyException(),
      'INVALID_SLIPPAGE_TOLERANCE' => const InvalidSlippageToleranceException(),
      'NO_INTERNAL_SWAP_ROUTES_FOUND' => const NoInternalSwapRoutesFoundException(),
      'NO_QUOTES' => const NoQuotesException(),
      'NO_SWAP_ROUTES_FOUND' => const NoSwapRoutesFoundException(),
      'ROUTE_TEMPORARILY_RESTRICTED' => const RouteTemporarilyRestrictedException(),
      'SANCTIONED_CURRENCY' => const SanctionedCurrencyException(),
      'SANCTIONED_WALLET_ADDRESS' => const SanctionedWalletAddressException(),
      'SWAP_IMPACT_TOO_HIGH' => const SwapImpactTooHighException(),
      'UNAUTHORIZED' => const UnauthorizedException(),
      'UNSUPPORTED_CHAIN' => const UnsupportedChainException(),
      'UNSUPPORTED_CURRENCY' => const UnsupportedCurrencyException(),
      'UNSUPPORTED_EXECUTION_TYPE' => const UnsupportedExecutionTypeException(),
      'UNSUPPORTED_ROUTE' => const UnsupportedRouteException(),
      'USER_RECIPIENT_MISMATCH' => const UserRecipientMismatchException(),
      _ => throw RelayException(errorCode),
    };
  }
}

class CoinPairNotFoundException extends RelayException {
  const CoinPairNotFoundException()
      : super(
          'Coin pair not found',
        );
}

class AmountTooLowException extends RelayException {
  const AmountTooLowException()
      : super(
          'The amount provided is below the minimum threshold required for a quote.',
        );
}

class ChainDisabledException extends RelayException {
  const ChainDisabledException()
      : super(
          'The origin or destination chain is currently disabled or unsupported.',
        );
}

class ExtraTxsNotSupportedException extends RelayException {
  const ExtraTxsNotSupportedException()
      : super(
          'Extra transactions are not supported for this trade type.',
        );
}

class ForbiddenException extends RelayException {
  const ForbiddenException()
      : super(
          'User does not have the required role or permission.',
        );
}

class InsufficientFundsException extends RelayException {
  const InsufficientFundsException()
      : super(
          'The user’s wallet does not have enough balance to perform the swap.',
        );
}

class InsufficientLiquidityException extends RelayException {
  const InsufficientLiquidityException()
      : super(
          'There is not enough liquidity available to complete the swap.',
        );
}

class InvalidAddressException extends RelayException {
  const InvalidAddressException()
      : super(
          'The provided user address is not valid.',
        );
}

class InvalidExtraTxsException extends RelayException {
  const InvalidExtraTxsException()
      : super(
          'The total value of extra transactions exceeds the intended output.',
        );
}

class InvalidGasLimitForDepositSpecifiedTxsException extends RelayException {
  const InvalidGasLimitForDepositSpecifiedTxsException()
      : super(
          'Deposit-specified transactions are only allowed for exact output swaps.',
        );
}

class InvalidInputCurrencyException extends RelayException {
  const InvalidInputCurrencyException()
      : super(
          'The provided input currency address is invalid or not supported.',
        );
}

class InvalidOutputCurrencyException extends RelayException {
  const InvalidOutputCurrencyException()
      : super(
          'The provided output currency address is invalid or not supported.',
        );
}

class InvalidSlippageToleranceException extends RelayException {
  const InvalidSlippageToleranceException()
      : super(
          'Slippage value is not a valid integer string representing basis points.',
        );
}

class NoInternalSwapRoutesFoundException extends RelayException {
  const NoInternalSwapRoutesFoundException()
      : super(
          'No valid swap route exists internally for the selected token pair.',
        );
}

class NoQuotesException extends RelayException {
  const NoQuotesException()
      : super(
          'No available quotes for the given parameters.',
        );
}

class NoSwapRoutesFoundException extends RelayException {
  const NoSwapRoutesFoundException()
      : super(
          'No route was found to fulfill the quote request with the given parameters.',
        );
}

class RouteTemporarilyRestrictedException extends RelayException {
  const RouteTemporarilyRestrictedException()
      : super(
          'This route is temporarily restricted due to high traffic or throttling.',
        );
}

class SanctionedCurrencyException extends RelayException {
  const SanctionedCurrencyException()
      : super(
          'The token involved in the transaction is on a sanctions list.',
        );
}

class SanctionedWalletAddressException extends RelayException {
  const SanctionedWalletAddressException()
      : super(
          'The sender or recipient wallet address is sanctioned or blacklisted.',
        );
}

class SwapImpactTooHighException extends RelayException {
  const SwapImpactTooHighException()
      : super(
          'The swap’s price impact exceeds acceptable thresholds.',
        );
}

class UnauthorizedException extends RelayException {
  const UnauthorizedException()
      : super(
          'The user is not authenticated or lacks valid authorization.',
        );
}

class UnsupportedChainException extends RelayException {
  const UnsupportedChainException()
      : super(
          'The specified chain is not supported by the platform.',
        );
}

class UnsupportedCurrencyException extends RelayException {
  const UnsupportedCurrencyException()
      : super(
          'The specified currency is not supported for input or output.',
        );
}

class UnsupportedExecutionTypeException extends RelayException {
  const UnsupportedExecutionTypeException()
      : super(
          'The execution type used is not supported for fee estimation or execution.',
        );
}

class UnsupportedRouteException extends RelayException {
  const UnsupportedRouteException()
      : super(
          'The swap route combination is not supported.',
        );
}

class UserRecipientMismatchException extends RelayException {
  const UserRecipientMismatchException()
      : super(
          'User and recipient addresses must match for this type of swap.',
        );
}
