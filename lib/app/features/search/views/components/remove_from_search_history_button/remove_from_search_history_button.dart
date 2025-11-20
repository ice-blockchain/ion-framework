// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

enum RemoveFromSearchHistoryButtonStyle {
  overlay,
  inline,
}

class RemoveFromSearchHistoryButton extends StatelessWidget {
  const RemoveFromSearchHistoryButton({
    required this.onDelete,
    this.style = RemoveFromSearchHistoryButtonStyle.overlay,
    super.key,
  });

  final VoidCallback onDelete;
  final RemoveFromSearchHistoryButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onDelete,
      behavior: HitTestBehavior.opaque,
      child: style == RemoveFromSearchHistoryButtonStyle.overlay
          ? Container(
              width: 20.0.s,
              height: 20.0.s,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Assets.svg.iconSheetClose.icon(
                  size: 12.0.s,
                  color: context.theme.appColors.tertiaryText,
                ),
              ),
            )
          : Padding(
              padding: EdgeInsetsDirectional.only(start: 8.0.s),
              child: Assets.svg.iconSheetClose.icon(
                size: 20.0.s,
                color: context.theme.appColors.tertiaryText,
              ),
            ),
    );

    if (style == RemoveFromSearchHistoryButtonStyle.overlay) {
      return PositionedDirectional(
        top: -4.0.s,
        end: -4.0.s,
        child: button,
      );
    }

    return button;
  }
}
