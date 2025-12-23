// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class SumPercentageAction extends StatelessWidget {
  const SumPercentageAction({
    required this.percentage,
    required this.onPercentageChanged,
    this.text,
    super.key,
  });

  final int percentage;
  final void Function(int) onPercentageChanged;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return GestureDetector(
      onTap: () {
        onPercentageChanged(percentage);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
        decoration: BoxDecoration(
          color: colors.attentionBlock,
          borderRadius: BorderRadius.circular(16.0.s),
        ),
        child: Text(
          text ?? '${percentage.toStringAsFixed(0)}%',
          style: textStyles.caption3.copyWith(
            color: colors.quaternaryText,
            height: 1.63,
          ),
        ),
      ),
    );
  }
}
