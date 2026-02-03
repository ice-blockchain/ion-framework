// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/views/utils/amount_validator.dart';
import 'package:ion/app/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/app/utils/text_input_formatters.dart';

class CoinAmountInput extends HookWidget {
  const CoinAmountInput({
    required this.controller,
    this.balanceUSD,
    this.maxValue,
    this.coin,
    this.enabled = true,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final double? balanceUSD;
  final double? maxValue;
  final CoinData? coin;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final locale = context.i18n;
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    final label = locale.wallet_coin_amount(coin?.abbreviation ?? '');
    final isValidInput = useState(true);

    return Column(
      children: [
        TextInput(
          enabled: enabled,
          controller: controller,
          autoValidateMode: AutovalidateMode.always,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onValidated: (isValid) => isValidInput.value = isValid,
          inputFormatters: [
            CoinInputFormatter(),
          ],
          validator: (value) => amountValidator(
            value: value,
            context: context,
            maxValue: maxValue,
            coin: coin,
          ),
          labelText: label,
          errorText: errorText,
          suffixIcon: maxValue != null && enabled
              ? Padding(
                  padding: EdgeInsetsDirectional.only(end: 16.0.s),
                  child: TextButton(
                    onPressed: () {
                      controller.text = formatCrypto(maxValue ?? 0);
                    },
                    child: Text(
                      locale.wallet_max,
                      style: textTheme.caption.copyWith(
                        color: isValidInput.value
                            ? context.theme.appColors.primaryAccent
                            : context.theme.appColors.attentionRed,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        if (balanceUSD != null)
          Column(
            children: [
              SizedBox(height: 6.0.s),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  locale.wallet_approximate_in_usd(
                    formatUSD(balanceUSD!),
                  ),
                  style: textTheme.caption2.copyWith(
                    color: colors.tertiaryText,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
