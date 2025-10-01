// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/scroll_button/scroll_button.dart';
import 'package:ion/app/extensions/extensions.dart';

class ScrollToBottomButton extends StatelessWidget {
  const ScrollToBottomButton({
    required this.scrollController,
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      bottom: 16.0.s,
      end: 16.0.s,
      child: ScrollButton(
        scrollController: scrollController,
        direction: ScrollDirection.down,
        onTap: onTap,
      ),
    );
  }
}
