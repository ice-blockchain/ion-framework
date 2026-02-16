// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class QuoteCloseButton extends StatelessWidget {
  const QuoteCloseButton({
    required this.isTc,
    required this.onTap,
    super.key,
  });

  final bool isTc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isTc) {
      return _TcQuoteCloseButton(onTap: onTap);
    }
    return _PostQuoteCloseButton(onTap: onTap);
  }
}

class _PostQuoteCloseButton extends StatelessWidget {
  const _PostQuoteCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 24.s,
        height: 24.s,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.appColors.tertiaryBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Assets.svg.iconSheetClose.icon(
                size: 16.s,
                color: theme.appColors.tertiaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TcQuoteCloseButton extends StatelessWidget {
  const _TcQuoteCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Assets.svg.iconFieldClearall.icon(size: 24.0.s),
    );
  }
}
