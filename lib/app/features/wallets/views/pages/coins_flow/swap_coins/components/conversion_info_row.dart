// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/generated/assets.gen.dart';

// TODO(ice-erebus): add high impact and not enough states
class ConversionInfoRow extends StatelessWidget {
  const ConversionInfoRow({
    required this.providerName,
    required this.sellCoin,
    required this.buyCoin,
    super.key,
  });

  final String providerName;
  final CoinsGroup sellCoin;
  final CoinsGroup buyCoin;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: 25.0.s,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // TODO(ice-erebus): implement conversion info
          Text(
            '1 ${sellCoin.name} = X ${buyCoin.name}',
            style: textStyles.body2.copyWith(),
          ),
          Row(
            spacing: 4.0.s,
            children: [
              Text(
                providerName,
                style: textStyles.body2.copyWith(),
              ),
              Assets.svg.iconBlockInformation.icon(
                color: colors.tertiaryText,
                size: 16.0.s,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
