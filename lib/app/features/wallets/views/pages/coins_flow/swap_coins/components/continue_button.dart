// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class ContinueButton extends StatelessWidget {
  const ContinueButton({
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Button(
        onPressed: onPressed,
        label: Text(
          context.i18n.wallet_swap_coins_continue,
          style: textStyles.body.copyWith(
            color: colors.secondaryBackground,
          ),
        ),
        backgroundColor: isEnabled ? colors.primaryAccent : colors.sheetLine.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.0.s),
        trailingIcon: Assets.svg.iconButtonNext.icon(
          color: colors.secondaryBackground,
          size: 24.0.s,
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 56.0.s),
          padding: EdgeInsets.symmetric(
            horizontal: 109.0.s,
            vertical: 16.0.s,
          ),
        ),
      ),
    );
  }
}
