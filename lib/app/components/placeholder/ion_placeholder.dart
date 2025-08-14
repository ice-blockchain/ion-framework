// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class IonPlaceholder extends StatelessWidget {
  const IonPlaceholder({super.key, this.isPlaceholder = false});

  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.theme.appColors.tertiaryBackground,
      child: isPlaceholder
          ? const SizedBox.shrink()
          : Center(
              child: Assets.svg.iconFeedUnavailable.icon(
                size: 40.0.s,
                color: context.theme.appColors.sheetLine,
              ),
            ),
    );
  }
}
