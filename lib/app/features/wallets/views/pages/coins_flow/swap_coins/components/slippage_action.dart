// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class SlippageAction extends StatelessWidget {
  const SlippageAction({
    required this.slippage,
    required this.defaultSlippage,
    required this.onSlippageChanged,
    required this.isVisible,
    super.key,
  });

  final double slippage;
  final double defaultSlippage;
  final ValueChanged<double> onSlippageChanged;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Button(
      onPressed: () async {
        final result = await SwapSlippageSettingsRoute(
          slippage: slippage,
          defaultSlippage: defaultSlippage,
        ).push<double>(context);

        if (result != null) {
          onSlippageChanged(result);
        }
      },
      type: ButtonType.outlined,
      tintColor: colors.onTertiaryFill,
      borderRadius: BorderRadius.circular(10.0.s),
      leadingIcon: Assets.svg.iconButtonManagecoin.icon(
        color: colors.primaryText,
        size: 14.0.s,
      ),
      label: Text(
        '${slippage.toStringAsFixed(1)}%',
        style: textStyles.body.copyWith(
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
