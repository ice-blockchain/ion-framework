// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/speech_bubble/speech_bubble.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats_data.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileTokenStatsInfo extends StatelessWidget {
  const ProfileTokenStatsInfo({
    this.data,
    super.key,
  });

  final ProfileTokenStatsData? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.53.s),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 34.0.s,
          vertical: 16.0.s,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatItem(
              icon: Assets.svg.iconMemeMarketcap,
              text: data!.marketCap,
            ),
            _StatItem(
              icon: Assets.svg.iconMemeMarkers,
              text: data!.price,
            ),
            _StatItem(
              icon: Assets.svg.iconSearchGroups,
              text: data!.volume,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileTokenStats extends StatelessWidget {
  const ProfileTokenStats({
    this.data,
    super.key,
  });

  final ProfileTokenStatsData? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _BuyHint(),
          SizedBox(width: 8.0.s),
          const BuyButton(),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItem(
          icon: Assets.svg.iconMemeMarketcap,
          text: data!.marketCap,
        ),
        _StatItem(
          icon: Assets.svg.iconMemeMarkers,
          text: data!.price,
        ),
        _StatItem(
          icon: Assets.svg.iconSearchGroups,
          text: data!.volume,
        ),
        const BuyButton(),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.text,
  });

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 3.13.s),
        Container(
          width: 14.15.s,
          height: 14.15.s,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(),
          child: Center(
            child: icon.icon(
              size: 14.15.s,
              color: context.theme.appColors.secondaryBackground,
            ),
          ),
        ),
        SizedBox(width: 3.13.s),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.theme.appTextThemes.caption.copyWith(
              color: context.theme.appColors.secondaryBackground,
              fontFamily: 'Noto Sans',
              fontWeight: FontWeight.w600,
              height: 1.17,
            ),
          ),
        ),
      ],
    );
  }
}

class _BuyHint extends StatelessWidget {
  const _BuyHint();

  @override
  Widget build(BuildContext context) {
    return SpeechBubble(
      height: 24.0.s,
      child: Container(
        height: 24.0.s,
        padding: EdgeInsetsDirectional.only(top: 4.0.s, bottom: 4.0.s, start: 12.0.s, end: 12.0.s),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Assets.svg.streamlineUltimateGamingRibbonFirst.icon(
              size: 14.0.s,
              color: context.theme.appColors.primaryText,
            ),
            SizedBox(width: 3.13.s),
            Text(
              context.i18n.profile_token_be_first_to_buy,
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.primaryText,
                fontFamily: 'Noto Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 3.13.s),
          ],
        ),
      ),
    );
  }
}

class BuyButton extends StatelessWidget {
  const BuyButton({
    this.height = 23.0,
    super.key,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.s,
      padding: EdgeInsets.symmetric(horizontal: 22.0.s),
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.32.s),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: Center(
              child: Assets.svg.iconWorkBuycoin.icon(
                size: 14.s,
                color: context.theme.appColors.secondaryBackground,
              ),
            ),
          ),
          SizedBox(width: 3.13.s),
          Text(
            context.i18n.profile_token_buy,
            style: context.theme.appTextThemes.caption3.copyWith(
              color: context.theme.appColors.secondaryBackground,
              fontFamily: 'Noto Sans',
              fontWeight: FontWeight.w600,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}
