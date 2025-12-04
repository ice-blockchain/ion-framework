// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';

class OkxException extends IonSwapException {
  const OkxException(this.code, [super.message]);

  factory OkxException.fromCode(int code) {
    return switch (code) {
      80000 => const OkxRepeatedRequestException(),
      80001 => const OkxCallDataExceedsLimitException(),
      80002 => const OkxTokenObjectCountLimitException(),
      80003 => const OkxNativeTokenObjectCountLimitException(),
      80004 => const OkxSuiObjectQueryTimeoutException(),
      80005 => const OkxInsufficientSuiObjectsException(),
      82000 => const OkxInsufficientLiquidityException(),
      82003 => const OkxInvalidReferrerWalletAddressException(),
      82102 => const OkxBelowMinimumQuantityException(),
      82103 => const OkxExceedsMaximumQuantityException(),
      82104 => const OkxTokenNotSupportedException(),
      82112 => const OkxQuoteRouteDifferenceException(),
      82116 => const OkxCallDataExceedsMaximumException(),
      82130 => const OkxChainNoAuthorizationRequiredException(),
      82004 => const OkxFourMemeCommissionSplitNotSupportedException(),
      82005 => const OkxAspectaCommissionSplitNotSupportedException(),
      _ => throw OkxException(code, 'Unknown OKX error code: $code'),
    };
  }

  final int code;
}

/// Repeated request
class OkxRepeatedRequestException extends OkxException {
  const OkxRepeatedRequestException()
      : super(
          80000,
          'Repeated request',
        );
}

/// CallData exceeds the maximum limit. Try again in 5 minutes.
class OkxCallDataExceedsLimitException extends OkxException {
  const OkxCallDataExceedsLimitException()
      : super(
          80001,
          'CallData exceeds the maximum limit. Try again in 5 minutes.',
        );
}

/// Requested token Object count has reached the limit.
class OkxTokenObjectCountLimitException extends OkxException {
  const OkxTokenObjectCountLimitException()
      : super(
          80002,
          'Requested token Object count has reached the limit.',
        );
}

/// Requested native token Object count has reached the limit.
class OkxNativeTokenObjectCountLimitException extends OkxException {
  const OkxNativeTokenObjectCountLimitException()
      : super(
          80003,
          'Requested native token Object count has reached the limit.',
        );
}

/// Timeout when querying SUI Object.
class OkxSuiObjectQueryTimeoutException extends OkxException {
  const OkxSuiObjectQueryTimeoutException()
      : super(
          80004,
          'Timeout when querying SUI Object.',
        );
}

/// Not enough Sui objects under the address for swapping
class OkxInsufficientSuiObjectsException extends OkxException {
  const OkxInsufficientSuiObjectsException()
      : super(
          80005,
          'Not enough Sui objects under the address for swapping',
        );
}

/// Insufficient liquidity
class OkxInsufficientLiquidityException extends OkxException {
  const OkxInsufficientLiquidityException()
      : super(
          82000,
          'Insufficient liquidity',
        );
}

/// toTokenReferrerWalletAddress address is not valid
class OkxInvalidReferrerWalletAddressException extends OkxException {
  const OkxInvalidReferrerWalletAddressException()
      : super(
          82003,
          'toTokenReferrerWalletAddress address is not valid',
        );
}

/// Less than the minimum quantity limit,the minimum amount is {0}
class OkxBelowMinimumQuantityException extends OkxException {
  const OkxBelowMinimumQuantityException()
      : super(
          82102,
          'Less than the minimum quantity limit',
        );
}

/// Exceeds than the maximum quantity limit,the maximum amount is {0}
class OkxExceedsMaximumQuantityException extends OkxException {
  const OkxExceedsMaximumQuantityException()
      : super(
          82103,
          'Exceeds the maximum quantity limit.',
        );
}

/// This token is not supported
class OkxTokenNotSupportedException extends OkxException {
  const OkxTokenNotSupportedException()
      : super(
          82104,
          'This token is not supported',
        );
}

/// The value difference from this transaction's quote route is higher than {num}, which may cause asset loss,The default value is 90%. It can be adjusted using the string age.
class OkxQuoteRouteDifferenceException extends OkxException {
  const OkxQuoteRouteDifferenceException()
      : super(
          82112,
          "The value difference from this transaction's quote",
        );
}

/// callData exceeds the maximum limit. Try again in 5 minutes.
class OkxCallDataExceedsMaximumException extends OkxException {
  const OkxCallDataExceedsMaximumException()
      : super(
          82116,
          'callData exceeds the maximum limit. Try again in 5 minutes.',
        );
}

/// The chain does not require authorized transactions and can be exchanged directly.
class OkxChainNoAuthorizationRequiredException extends OkxException {
  const OkxChainNoAuthorizationRequiredException()
      : super(
          82130,
          'The chain does not require authorized transactions and can be exchanged directly.',
        );
}

/// Commission split for swaps via Four.meme is not supported
class OkxFourMemeCommissionSplitNotSupportedException extends OkxException {
  const OkxFourMemeCommissionSplitNotSupportedException()
      : super(
          82004,
          'Commission split for swaps via Four.meme is not supported',
        );
}

/// Commission split for swaps via aspecta is not supported
class OkxAspectaCommissionSplitNotSupportedException extends OkxException {
  const OkxAspectaCommissionSplitNotSupportedException()
      : super(
          82005,
          'Commission split for swaps via aspecta is not supported',
        );
}
