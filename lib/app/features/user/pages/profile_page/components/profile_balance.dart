// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/components/dividers/gradient_vertical_divider.dart';
import 'package:ion/app/components/shapes/bottom_notch_rect_border.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/token_card_builder.dart';
import 'package:ion/app/utils/formatters.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileBalance extends StatelessWidget {
  const ProfileBalance({
    required this.height,
    required this.coins,
    required this.amount,
    required this.externalAddress,
    super.key,
  });

  final double height;
  final double coins;
  final double amount;
  final String externalAddress;
  @override
  Widget build(BuildContext context) {
    return TokenCardBuilder(
      externalAddress: externalAddress,
      skeleton: _Skeleton(height: height),
      builder: (token, _) => Container(
        height: height,
        decoration: ShapeDecoration(
          color: context.theme.appColors.backgroundBlue,
          shape: const BottomNotchRectBorder(),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.s, vertical: 16.0.s),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Assets.svg.iconMemeCoins.icon(size: 16.s),
                    SizedBox(
                      width: 4.0.s,
                    ),
                    Text(
                      formatTokenAmountWithSubscript(coins),
                      style: context.theme.appTextThemes.body2.copyWith(
                        color: context.theme.appColors.primaryBackground,
                      ),
                    ),
                  ],
                ),
              ),
              const GradientVerticalDivider(),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Assets.svg.iconCreatecoinDollar.icon(size: 16.s),
                    SizedBox(
                      width: 1.0.s,
                    ),
                    Text(
                      formatUSD(amount),
                      style: context.theme.appTextThemes.body2.copyWith(
                        color: context.theme.appColors.primaryBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Container(
        height: height,
        decoration: ShapeDecoration(
          color: context.theme.appColors.backgroundBlue,
          shape: const BottomNotchRectBorder(),
        ),
      ),
    );
  }
}
