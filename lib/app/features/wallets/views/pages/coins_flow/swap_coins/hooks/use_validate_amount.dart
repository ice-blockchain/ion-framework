// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/views/utils/amount_validator.dart';

void useValidateAmount({
  required TextEditingController? controller,
  required FocusNode focusNode,
  required CoinInWalletData? coinForNetwork,
  required BuildContext context,
  required ValueChanged<String?>? onValidationError,
  required CoinsGroup? coinsGroup,
  required bool skipValidation,
}) {
  useEffect(
    () {
      void validateAndNotify() {
        if (onValidationError == null || skipValidation) return;

        final error = _validateAmount(
          controller?.text,
          context,
          coinForNetwork,
          coinsGroup,
        );
        onValidationError(error);
      }

      void onTextChanged() {
        validateAndNotify();
      }

      void onFocusChanged() {
        validateAndNotify();
      }

      controller?.addListener(onTextChanged);
      focusNode.addListener(onFocusChanged);

      // Validate initially
      WidgetsBinding.instance.addPostFrameCallback((_) {
        validateAndNotify();
      });

      return () {
        controller?.removeListener(onTextChanged);
        focusNode.removeListener(onFocusChanged);
      };
    },
    [
      controller,
      focusNode,
      coinForNetwork,
      onValidationError,
      coinsGroup,
    ],
  );
}

String? _validateAmount(
  String? value,
  BuildContext context,
  CoinInWalletData? coinForNetwork,
  CoinsGroup? coinsGroup,
) {
  final abbreviation = coinsGroup?.abbreviation ?? '';
  final insufficientFundsError = '${context.i18n.wallet_coin_amount_insufficient} $abbreviation';
  final decimals = coinForNetwork?.coin.decimals;

  return amountValidator(
    value: value,
    context: context,
    maxValue: coinForNetwork?.amount,
    coin: coinForNetwork?.coin,
    insufficientFundsError: insufficientFundsError,
    decimalsForNetwork: decimals,
  );
}
