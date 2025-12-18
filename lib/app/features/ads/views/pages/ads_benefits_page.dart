// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/card/rounded_card.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/theme/app_colors.dart';
import 'package:ion/app/theme/app_text_themes.dart';
import 'package:ion/generated/assets.gen.dart';

class AdsBenefitsPage extends HookConsumerWidget {
  const AdsBenefitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileBackground(
              colors: useAvatarFallbackColors,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 450.0.s,
                  ),
                  Positioned.fill(
                    child: SvgPicture.asset(
                      Assets.svg.lightBeams,
                      fit: BoxFit.cover,
                    ),
                  ),
                  PositionedDirectional(
                    start: 17.s,
                    end: 17.s,
                    bottom: 15,
                    child: Image.asset(
                      Assets.images.ads.adsBenefits.path,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    end: 0,
                    child: Center(
                      child: SizedBox(
                        width: 300.0.s,
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: MediaQuery.paddingOf(context).top + 25.0.s,
                          ),
                          child: Text(
                            context.i18n.ads_benefits_title,
                            textAlign: TextAlign.center,
                            style: context.theme.appTextThemes.headline1.copyWith(
                              color: Colors.white,
                              fontSize: 36,
                              height: 1.22,
                              letterSpacing: 0.36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: MediaQuery.paddingOf(context).top,
                    end: 16.0.s,
                    child: const NavigationCloseButton(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Content card with rounded top corners overlapping the background
            Transform.translate(
              offset: Offset(0, -30.0.s), // Negative offset to overlap
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.secondaryBackground,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(30.0.s),
                    topEnd: Radius.circular(30.0.s),
                  ),
                ),
                child: ScreenSideOffset.small(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30.0.s),
                      // Creator-focused revenue section
                      _CreatorFocusedRevenueSection(
                        colors: colors,
                        textStyles: context.theme.appTextThemes,
                      ),
                      SizedBox(height: 16.0.s),
                      // Percentage cards (50% Creator, 50% Burn)
                      _PercentageCards(colors: colors, textStyles: context.theme.appTextThemes),
                      SizedBox(height: 16.0.s),
                      // Benefits for creators section
                      _BenefitsForCreatorsSection(
                        colors: colors,
                        textStyles: context.theme.appTextThemes,
                      ),
                      SizedBox(height: 16.0.s),
                      // Four benefit cards
                      _BenefitCards(colors: colors, textStyles: context.theme.appTextThemes),
                      SizedBox(height: 12.0.s),
                      // A sustainable advertising model section
                      _SustainableModelSection(
                        colors: colors,
                        textStyles: context.theme.appTextThemes,
                      ),
                      SizedBox(height: 16.0.s),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Creator-focused revenue section
class _CreatorFocusedRevenueSection extends StatelessWidget {
  const _CreatorFocusedRevenueSection({
    required this.colors,
    required this.textStyles,
  });

  final AppColorsExtension colors;
  final AppTextThemesExtension textStyles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.i18n.ads_benefits_creator_focused_revenue_title,
          style: textStyles.title.copyWith(
            color: colors.primaryText,
          ),
        ),
        SizedBox(height: 12.0.s),
        Text(
          context.i18n.ads_benefits_creator_focused_revenue_description_part_1,
          style: textStyles.body2.copyWith(
            color: colors.sharkText,
          ),
        ),
        SizedBox(height: 12.0.s),
        Text(
          context.i18n.ads_benefits_creator_focused_revenue_description_part_2,
          style: textStyles.body2.copyWith(
            color: colors.sharkText,
          ),
        ),
      ],
    );
  }
}

// Percentage cards (50% Creator, 50% Burn)
class _PercentageCards extends StatelessWidget {
  const _PercentageCards({
    required this.colors,
    required this.textStyles,
  });

  final AppColorsExtension colors;
  final AppTextThemesExtension textStyles;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: RoundedCard.outlined(
            backgroundColor: colors.primaryBackground,
            borderColor: colors.onTertiaryFill,
            padding: EdgeInsets.all(18.0.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '50%',
                  style: textStyles.headline2.copyWith(
                    color: colors.primaryAccent,
                    height: 1.29,
                  ),
                ),
                SizedBox(height: 8.0.s),
                Text(
                  context.i18n.ads_benefits_percentage_creator,
                  style: textStyles.caption2.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 9.0.s),
        Expanded(
          child: RoundedCard.outlined(
            backgroundColor: colors.primaryBackground,
            borderColor: colors.onTertiaryFill,
            padding: EdgeInsets.all(18.0.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '50%',
                  style: textStyles.headline2.copyWith(
                    color: colors.primaryAccent,
                    height: 1.29,
                  ),
                ),
                SizedBox(height: 8.0.s),
                Text(
                  context.i18n.ads_benefits_percentage_burn,
                  style: textStyles.caption2.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Benefits for creators section
class _BenefitsForCreatorsSection extends StatelessWidget {
  const _BenefitsForCreatorsSection({
    required this.colors,
    required this.textStyles,
  });

  final AppColorsExtension colors;
  final AppTextThemesExtension textStyles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.i18n.ads_benefits_benefits_for_creators_title,
          style: textStyles.title.copyWith(
            color: colors.primaryText,
          ),
        ),
        SizedBox(height: 12.0.s),
        Text(
          context.i18n.ads_benefits_benefits_for_creators_description,
          style: textStyles.body2.copyWith(
            color: colors.sharkText,
          ),
        ),
      ],
    );
  }
}

// Four benefit cards
class _BenefitCards extends StatelessWidget {
  const _BenefitCards({
    required this.colors,
    required this.textStyles,
  });

  final AppColorsExtension colors;
  final AppTextThemesExtension textStyles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BenefitCard(
          title: context.i18n.ads_benefits_daily_payouts_title,
          description: context.i18n.ads_benefits_daily_payouts_description,
          icon: Assets.svg.iconProfileTips,
          colors: colors,
          textStyles: textStyles,
        ),
        SizedBox(height: 9.0.s),
        _BenefitCard(
          title: context.i18n.ads_benefits_effortless_monetization_title,
          description: context.i18n.ads_benefits_effortless_monetization_description,
          icon: Assets.svg.iconAdsMonetization,
          colors: colors,
          textStyles: textStyles,
        ),
        SizedBox(height: 9.0.s),
        _BenefitCard(
          title: context.i18n.ads_benefits_scales_with_activity_title,
          description: context.i18n.ads_benefits_scales_with_activity_description,
          icon: Assets.svg.iconAdsActivity,
          colors: colors,
          textStyles: textStyles,
        ),
        SizedBox(height: 9.0.s),
        _BenefitCard(
          title: context.i18n.ads_benefits_ecosystem_rewards_title,
          description: context.i18n.ads_benefits_ecosystem_rewards_description,
          icon: Assets.svg.iconAdsReward,
          colors: colors,
          textStyles: textStyles,
        ),
      ],
    );
  }
}

// Individual benefit card
class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.textStyles,
  });

  final String title;
  final String description;
  final String icon;
  final AppColorsExtension colors;
  final AppTextThemesExtension textStyles;

  @override
  Widget build(BuildContext context) {
    return RoundedCard.filled(
      backgroundColor: colors.primaryBackground,
      padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 20.0.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon.icon(
            size: 20.0.s,
            color: colors.primaryAccent,
          ),
          SizedBox(height: 6.0.s),
          Text(
            title,
            style: textStyles.headline2.copyWith(
              color: colors.sharkText,
              height: 1.29,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0.s),
          Text(
            description,
            style: textStyles.caption2.copyWith(
              color: colors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// A sustainable advertising model section
class _SustainableModelSection extends StatelessWidget {
  const _SustainableModelSection({
    required this.colors,
    required this.textStyles,
  });

  final AppColorsExtension colors;
  final AppTextThemesExtension textStyles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.i18n.ads_benefits_sustainable_model_title,
          style: textStyles.title.copyWith(
            color: colors.primaryText,
          ),
        ),
        SizedBox(height: 12.0.s),
        Text(
          context.i18n.ads_benefits_sustainable_model_description_part_1,
          style: textStyles.body2.copyWith(
            color: colors.sharkText,
          ),
        ),
        SizedBox(height: 12.0.s),
        Text(
          context.i18n.ads_benefits_sustainable_model_description_part_2,
          style: textStyles.body2.copyWith(
            color: colors.sharkText,
          ),
        ),
      ],
    );
  }
}
