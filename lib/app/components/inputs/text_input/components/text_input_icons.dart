// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons_divider.dart';
import 'package:ion/app/extensions/num.dart';

class TextInputIcons extends StatelessWidget {
  const TextInputIcons({
    required this.icons,
    super.key,
    this.hasLeftDivider = false,
    this.hasRightDivider = false,
    this.minWidth,
  });

  final List<Widget> icons;

  final bool hasLeftDivider;

  final bool hasRightDivider;

  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLeftDivider)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 16.0.s),
            child: const TextInputIconsDivider(),
          ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth ?? 56.0.s,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: icons,
          ),
        ),
        if (hasRightDivider)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 16.0.s),
            child: const TextInputIconsDivider(),
          ),
      ],
    );
  }
}
