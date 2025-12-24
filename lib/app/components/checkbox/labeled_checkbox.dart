// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    required this.isChecked,
    required this.onChanged,
    required this.label,
    this.textStyle,
    this.mainAxisAlignment,
    super.key,
  });

  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final String label;
  final TextStyle? textStyle;
  final MainAxisAlignment? mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!isChecked),
      child: Row(
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.center,
        children: [
          (isChecked ? Assets.svg.iconBlockCheckboxOn : Assets.svg.iconBlockCheckboxOff)
              .icon(size: 20.0.s),
          SizedBox(width: 6.0.s),
          Text(
            label,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
