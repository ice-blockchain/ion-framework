import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class SwapCoinsMessageInfo extends StatelessWidget {
  const SwapCoinsMessageInfo({
    required this.sellCoinAbbreviation,
    required this.buyCoinAbbreviation,
    super.key,
  });

  final String? sellCoinAbbreviation;
  final String? buyCoinAbbreviation;

  @override
  Widget build(BuildContext context) {
    if (sellCoinAbbreviation == null || buyCoinAbbreviation == null) {
      return const SizedBox.shrink();
    }

    return Row(
      spacing: 4.0.s,
      children: [
        Text(
          '\$$sellCoinAbbreviation',
          style: context.theme.appTextThemes.body.copyWith(
            color: context.theme.appColors.onPrimaryAccent,
          ),
        ),
        RotatedBox(
          quarterTurns: 2,
          child: Assets.svg.iconBackArrow.icon(
            color: context.theme.appColors.onTertiaryFill,
            size: 16.0.s,
          ),
        ),
        Text(
          '\$$buyCoinAbbreviation',
          style: context.theme.appTextThemes.body.copyWith(
            color: context.theme.appColors.onPrimaryAccent,
          ),
        ),
      ],
    );
  }
}
