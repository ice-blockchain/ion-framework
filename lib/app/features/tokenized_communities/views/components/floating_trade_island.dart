// SPDX-License-Identifier: ice License 1.0

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_operation_protected_accounts_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class FloatingTradeIsland extends ConsumerWidget {
  const FloatingTradeIsland({
    this.eventReference,
    this.externalAddress,
    super.key,
  }) : assert(
          (eventReference == null) != (externalAddress == null),
          'Either eventReference or externalAddress must be provided',
        );

  final EventReference? eventReference;
  final String? externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if this account is protected from token operations
    final protectedAccountsService = ref.read(tokenOperationProtectedAccountsServiceProvider);
    final isProtected = eventReference != null
        ? protectedAccountsService.isProtectedAccountEvent(eventReference!)
        : protectedAccountsService.isProtectedAccountFromExternalAddress(externalAddress!);
    if (isProtected) {
      return const SizedBox.shrink();
    }

    final colors = context.theme.appColors;
    final i18n = context.i18n;

    return PhysicalModel(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(20.s),
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Container(
        padding: EdgeInsets.all(10.s),
        decoration: BoxDecoration(
          color: colors.onPrimaryAccent,
          borderRadius: BorderRadius.circular(20.s),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PillButton(
              color: colors.success,
              leading: Assets.svg.iconButtonReceive.icon(size: 20.s, color: Colors.white),
              label: i18n.trade_buy,
              customPainter: _TradeButtonPainter.buy(color: colors.success),
              onTap: () {
                TradeCommunityTokenRoute(
                  eventReference: eventReference?.encode(),
                  externalAddress: externalAddress,
                  initialMode: CommunityTokenTradeMode.buy,
                ).push<void>(context);
              },
              flipIconUp: true,
            ),
            SizedBox(width: 2.s),
            _PillButton(
              color: colors.lossRed,
              leading: Assets.svg.iconButtonReceive.icon(size: 20.s, color: Colors.white),
              label: i18n.trade_sell,
              customPainter: _TradeButtonPainter.sell(color: colors.lossRed),
              onTap: () {
                TradeCommunityTokenRoute(
                  eventReference: eventReference?.encode(),
                  externalAddress: externalAddress,
                  initialMode: CommunityTokenTradeMode.sell,
                ).push<void>(context);
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
    this.customPainter,
  });

  final Color color;
  final Widget leading;
  final String label;
  final VoidCallback? onTap;
  final bool flipIconUp;
  final CustomPainter? customPainter;

  @override
  Widget build(BuildContext context) {
    final texts = context.theme.appTextThemes;
    final iconWidget = flipIconUp ? Transform.rotate(angle: math.pi, child: leading) : leading;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: customPainter,
        child: Container(
          width: 140.s,
          height: 40.s,
          decoration: customPainter == null
              ? BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20.s),
                )
              : null,
          padding: EdgeInsets.symmetric(horizontal: 14.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              SizedBox(width: 4.s),
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
      ),
    );
  }
}

class _TradeButtonPainter extends CustomPainter {
  const _TradeButtonPainter.buy({required this.color}) : _isBuy = true;
  const _TradeButtonPainter.sell({required this.color}) : _isBuy = false;

  final Color color;
  final bool _isBuy;

  // Path was created by using the SVG data and then scaled to fit the widget size
  Path _createBuyPath() => Path()
    ..moveTo(0, 16)
    ..cubicTo(0, 7.16344, 7.16344, 0, 16, 0)
    ..lineTo(128.359, 0)
    ..cubicTo(134.767, 0, 139.521, 5.94216, 138.115, 12.1939)
    ..lineTo(134.575, 27.9387)
    ..cubicTo(132.933, 35.2405, 126.449, 40.4286, 118.965, 40.4286)
    ..lineTo(16, 40.4286)
    ..cubicTo(7.16346, 40.4286, 0, 33.2651, 0, 24.4286)
    ..lineTo(0, 16)
    ..close();

  // Path was created by using the SVG data and then scaled to fit the widget size
  Path _createSellPath() => Path()
    ..moveTo(138.363, 24.4287)
    ..cubicTo(138.363, 33.2653, 131.2, 40.4287, 122.363, 40.4287)
    ..lineTo(10.0045, 40.4287)
    ..cubicTo(3.59669, 40.4287, -1.15768, 34.4865, 0.248093, 28.2349)
    ..lineTo(3.78854, 12.49)
    ..cubicTo(5.43045, 5.18818, 11.9146, 0.000137329, 19.3988, 0.000137329)
    ..lineTo(122.363, 0.000137329)
    ..cubicTo(131.2, 0.000137329, 138.363, 7.16358, 138.363, 16.0001)
    ..lineTo(138.363, 24.4287)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    const svgWidth = 140;
    const svgHeight = 40;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = _isBuy ? _createBuyPath() : _createSellPath();

    // Scale the path to fit the widget size
    final scaleX = size.width / svgWidth;
    final scaleY = size.height / svgHeight;
    final matrix = Matrix4.diagonal3Values(scaleX, scaleY, 1);
    final scaledPath = path.transform(matrix.storage);

    canvas.drawPath(scaledPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TradeButtonPainter oldDelegate) {
    return color != oldDelegate.color || _isBuy != oldDelegate._isBuy;
  }
}
