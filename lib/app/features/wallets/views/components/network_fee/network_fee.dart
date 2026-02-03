// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/info_type.dart';
import 'package:ion/app/features/wallets/model/network_fee_option.f.dart';
import 'package:ion/app/features/wallets/views/components/info_block_button.dart';
import 'package:ion/app/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';

class NetworkFeeOptionWidget extends StatelessWidget {
  const NetworkFeeOptionWidget({
    required this.feeOption,
    super.key,
  });

  final NetworkFeeOption feeOption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.i18n.wallet_network_fee,
          style: context.theme.appTextThemes.body.copyWith(
            color: context.theme.appColors.primaryText,
          ),
        ),
        SizedBox(width: 6.s),
        InfoBlockButton(
          size: 16.s,
          infoType: InfoType.networkFee,
          color: context.theme.appColors.tertiaryText,
        ),
        const Spacer(),
        RichText(
          text: TextSpan(
            text: formatCrypto(feeOption.amount, feeOption.symbol),
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.primaryText,
            ),
            children: [
              const TextSpan(text: ' '),
              TextSpan(
                text: '(~\$${formatDouble(feeOption.priceUSD, maximumFractionDigits: 5)})',
                style: context.theme.appTextThemes.caption3.copyWith(
                  color: context.theme.appColors.quaternaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
