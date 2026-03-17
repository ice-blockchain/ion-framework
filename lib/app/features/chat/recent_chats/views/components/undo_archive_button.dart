// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

class UndoArchiveButton extends StatelessWidget {
  const UndoArchiveButton({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  static const _minTapTargetSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12.0.s,
          vertical: (_minTapTargetSize.s - 20.0.s) / 2,
        ),
        child: Text(
          context.i18n.button_undo,
          style: context.theme.appTextThemes.body.copyWith(
            color: context.theme.appColors.onPrimaryAccent,
            decoration: TextDecoration.underline,
            decorationColor: context.theme.appColors.onPrimaryAccent,
          ),
        ),
      ),
    );
  }
}
