// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_dialog.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/generated/assets.gen.dart';

class FloatingTradeIsland extends StatelessWidget {
  const FloatingTradeIsland({
    required this.externalAddress,
    super.key,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final i18n = context.i18n;

    return PhysicalModel(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(20.0.s),
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Container(
        padding: EdgeInsets.all(10.0.s),
        decoration: BoxDecoration(
          color: colors.onPrimaryAccent,
          borderRadius: BorderRadius.circular(20.0.s),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PillButton(
              color: colors.success,
              leading: Assets.svg.iconButtonReceive.icon(size: 20.0.s, color: Colors.white),
              label: i18n.trade_buy,
              onTap: () {
                showSimpleBottomSheet<void>(
                  context: context,
                  child: TradeCommunityTokenDialog(
                    externalAddress: externalAddress,
                    externalAddressType: const ExternalAddressType.ionConnectUser(),
                    mode: CommunityTokenTradeMode.buy,
                  ),
                );
              },
              flipIconUp: true,
            ),
            SizedBox(width: 10.0.s),
            _PillButton(
              color: colors.lossRed,
              leading: Assets.svg.iconButtonReceive.icon(size: 20.0.s, color: Colors.white),
              label: i18n.trade_sell,
              onTap: () {
                showSimpleBottomSheet<void>(
                  context: context,
                  child: TradeCommunityTokenDialog(
                    externalAddress: externalAddress,
                    externalAddressType: const ExternalAddressType.ionConnectUser(),
                    mode: CommunityTokenTradeMode.sell,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.color,
    required this.leading,
    required this.label,
    this.onTap,
    this.flipIconUp = false,
  });

  final Color color;
  final Widget leading;
  final String label;
  final VoidCallback? onTap;
  final bool flipIconUp;

  @override
  Widget build(BuildContext context) {
    final texts = context.theme.appTextThemes;
    final iconWidget = flipIconUp ? Transform.rotate(angle: math.pi, child: leading) : leading;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 140.857.s,
        height: 40.429.s,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.0.s),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.0.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            SizedBox(width: 4.0.s),
            Text(
              label,
              style: texts.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 18 / texts.body2.fontSize!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
