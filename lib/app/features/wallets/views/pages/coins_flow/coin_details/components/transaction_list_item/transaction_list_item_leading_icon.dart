// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/model/transaction_status.f.dart';
import 'package:ion/app/features/wallets/model/transaction_type.dart';
import 'package:ion/generated/assets.gen.dart';

class TransactionListItemLeadingIcon extends StatelessWidget {
  const TransactionListItemLeadingIcon({
    required this.type,
    required this.status,
    super.key,
  });

  final TransactionType type;
  final TransactionStatus status;

  Color _getBorderColor(BuildContext context) {
    return switch (type) {
      TransactionType.receive => context.theme.appColors.success,
      TransactionType.send => context.theme.appColors.onTertiaryFill,
    };
  }

  Color _getIconColor(BuildContext context) {
    if (status == TransactionStatus.failed) {
      return context.theme.appColors.attentionRed;
    }

    return switch (type) {
      TransactionType.receive => context.theme.appColors.secondaryBackground,
      TransactionType.send => context.theme.appColors.secondaryText,
    };
  }

  Color _getBackgroundColor(BuildContext context) {
    return switch (type) {
      TransactionType.receive => context.theme.appColors.success,
      TransactionType.send => context.theme.appColors.onPrimaryAccent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final showStatusLabel =
        status == TransactionStatus.broadcasted || status == TransactionStatus.failed;
    final mainIconSize = 36.0.s;
    final broadcastedIconMargin = 4.0.s;
    final widgetWidth = mainIconSize + broadcastedIconMargin;

    // Add broadcastedIconMargin twice to place the main icon at the vertical center
    final widgetHeight = mainIconSize + broadcastedIconMargin + broadcastedIconMargin;

    return SizedBox(
      height: widgetHeight,
      width: widgetWidth,
      child: Stack(
        children: [
          Positioned.directional(
            top: broadcastedIconMargin,
            start: 0,
            textDirection: direction,
            child: Container(
              width: mainIconSize,
              height: mainIconSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getBackgroundColor(context),
                borderRadius: BorderRadius.circular(10.0.s),
                border: Border.all(
                  color: _getBorderColor(context),
                  width: 1.0.s,
                ),
              ),
              child: type.iconAsset.icon(color: _getIconColor(context)),
            ),
          ),
          if (showStatusLabel)
            Positioned.directional(
              end: 0,
              bottom: 0,
              textDirection: direction,
              child: switch (status) {
                TransactionStatus.broadcasted => Assets.svg.iconhourglass.icon(size: 14.0.s),
                TransactionStatus.failed => Assets.svg.iconError.icon(size: 14.0.s),
                _ => const SizedBox.shrink(),
              },
            ),
        ],
      ),
    );
  }
}
