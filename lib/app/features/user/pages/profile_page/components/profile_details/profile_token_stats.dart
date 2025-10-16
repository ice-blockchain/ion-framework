// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion/app/components/speech_bubble/speech_bubble.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_token_stats_data.dart';
import 'package:ion/generated/assets.gen.dart';

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
          _buildBuyHint(context),
          SizedBox(
            width: 8.0.s,
          ),
          _buildBuyButton(context, iconAsset: Assets.svg.iconWorkBuycoin),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          context,
          icon: Assets.svg.iconMemeMarketcap,
          text: data!.marketCap,
        ),
        _buildStatItem(
          context,
          icon: Assets.svg.iconMemeMarkers,
          text: data!.price,
        ),
        _buildStatItem(
          context,
          icon: Assets.svg.iconSearchGroups,
          text: data!.volume,
        ),
        _buildBuyButton(context, iconAsset: Assets.svg.iconWorkBuycoin),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String text,
  }) {
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

  Widget _buildBuyHint(BuildContext context) {
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

  Widget _buildBuyButton(BuildContext context, {required String iconAsset}) {
    return Container(
      height: 23.0.s,
      padding: EdgeInsets.symmetric(horizontal: 10.0.s),
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
          SizedBox(width: 3.13.s),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 14.s,
                height: 14.s,
                colorFilter: ColorFilter.mode(
                  context.theme.appColors.secondaryBackground,
                  BlendMode.srcIn,
                ),
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
