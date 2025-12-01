// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class SlippageAction extends StatelessWidget {
  const SlippageAction({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Button(
      onPressed: () {
        // TODO(ice-erebus): implement slippage action
      },
      type: ButtonType.outlined,
      tintColor: colors.onTertiaryFill,
      borderRadius: BorderRadius.circular(10.0.s),
      leadingIcon: Assets.svg.iconButtonManagecoin.icon(
        color: colors.primaryText,
        size: 14.0.s,
      ),
      label: Text(
        '1%',
        style: textStyles.body2.copyWith(
          color: colors.primaryText,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(55.0.s, 26.0.s),
        padding: EdgeInsets.symmetric(
          horizontal: 10.0.s,
          vertical: 6.0.s,
        ),
      ),
    );
  }
}
