// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/utils/crypto_formatter.dart';

void useAmountListener(
  TextEditingController amountController,
  TradeCommunityTokenController controller,
  double currentAmount,
) {
  final isUpdatingFromState = useRef(false);

  useEffect(
    () {
      void listener() {
        if (isUpdatingFromState.value) return;

        final val = parseAmount(amountController.text) ?? 0;
        controller.setAmount(val);
      }

      amountController.addListener(listener);
      return () => amountController.removeListener(listener);
    },
    [amountController, controller],
  );

  useEffect(
    () {
      final currentText = parseAmount(amountController.text) ?? 0;
      if ((currentText - currentAmount).abs() > 0.0001) {
        isUpdatingFromState.value = true;
        amountController.text = currentAmount.toString();
        isUpdatingFromState.value = false;
      }
      return null;
    },
    [currentAmount, amountController],
  );
}

void useQuoteDisplay(
  TextEditingController quoteController,
  BigInt? quoteAmount, {
  required bool isQuoting,
  int decimals = 18,
}) {
  useEffect(
    () {
      if (quoteAmount != null && !isQuoting) {
        final quoteValue = formatCrypto(fromBlockchainUnits(quoteAmount.toString(), decimals));
        if (quoteController.text != quoteValue) quoteController.text = quoteValue;
      } else if (quoteAmount == null) {
        final zeroValue = formatCrypto(0);
        if (quoteController.text != zeroValue) quoteController.text = zeroValue;
      }
      return null;
    },
    [quoteAmount, isQuoting, quoteController, decimals],
  );
}
