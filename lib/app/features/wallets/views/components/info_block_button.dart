// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/info/info_modal.dart';
import 'package:ion/app/components/info/info_type.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class InfoBlockButton extends StatelessWidget {
  const InfoBlockButton({
    required this.infoType,
    super.key,
    this.color,
    this.size,
  });

  final InfoType infoType;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 16.0.s;
    final iconColor = color ?? context.theme.appColors.primaryAccent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showSimpleBottomSheet<void>(
          context: context,
          child: InfoModal(
            infoType: infoType,
          ),
        );
      },
      child: IconTheme(
        data: IconThemeData(
          size: iconSize,
        ),
        child: Assets.svg.iconBlockInformation.icon(
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}
