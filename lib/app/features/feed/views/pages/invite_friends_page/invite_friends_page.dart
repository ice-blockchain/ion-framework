// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/tooltip/copied_tooltip.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user/providers/user_social_profile_provider.r.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:share_plus/share_plus.dart';

class InviteFriendsPage extends HookConsumerWidget {
  const InviteFriendsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final (:opacity) = useAnimatedOpacityOnScroll(scrollController, topOffset: 60.0.s);

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
    );
    final userMetadataValue = ref.watch(currentUserMetadataProvider).valueOrNull;
    final referralCode = userMetadataValue?.data.name;

    final userSocialProfile = ref.watch(
      getUserSocialProfileProvider(
        userIdOrMasterKey: userMetadataValue?.masterPubkey ?? '',
      ),
    );

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: UnconstrainedBox(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 270.0.s,
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(top: 26.0.s, bottom: 20.0.s),
                        child: InfoCard(
                          iconAsset: Assets.svg.iconFeedProfileInvite,
                          title: context.i18n.invite_friends_page_title,
                          description: context.i18n.invite_friends_page_subtitle,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      16.0.s,
                      0,
                      16.0.s,
                      94.0.s,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8.0.s,
                      children: [
                        Row(
                          spacing: 8.0.s,
                          children: [
                            Expanded(
                              child: _PercentageCard(
                                title: context.i18n.invite_friends_percentage_first_month_label,
                                percentage: 50,
                              ),
                            ),
                            Expanded(
                              child: _PercentageCard(
                                title: context.i18n.invite_friends_percentage_lifetime_label,
                                percentage: 10,
                              ),
                            ),
                          ],
                        ),
                        const _EarningsCard(),
                        _SummaryCard(userSocialProfile: userSocialProfile),
                        if (referralCode case final referralCode?)
                          _ReferralCodeCard(
                            referralCode: referralCode,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: opacity,
              child: NavigationAppBar(
                useScreenTopOffset: true,
                backButtonIcon: backButtonIcon,
                scrollController: scrollController,
                horizontalPadding: 0,
                title: Text(
                  context.i18n.invite_friends_button,
                  style: context.theme.appTextThemes.subtitle2.copyWith(
                    color: context.theme.appColors.primaryText,
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.topStart,
              child: NavigationBackButton(
                context.pop,
                icon: backButtonIcon,
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.appColors.shadow.withAlpha(8),
                      blurRadius: 16.0.s,
                      offset: Offset(-2.0.s, -2.0.s),
                    ),
                  ],
                  color: context.theme.appColors.onPrimaryAccent,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.0.s, vertical: 12.0.s),
                child: Button(
                  leadingIcon: Assets.svg.iconButtonInvite.icon(
                    size: 24.0.s,
                    color: context.theme.appColors.onPrimaryAccent,
                  ),
                  label: Text(
                    context.i18n.invite_friends_button,
                    style: context.theme.appTextThemes.body,
                  ),
                  onPressed: () {
                    Share.share(
                      '${context.i18n.invite_friends_shared_link_text} https://online.io/@$referralCode',
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentageCard extends StatelessWidget {
  const _PercentageCard({
    required this.title,
    required this.percentage,
  });
  final String title;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return _IonCard(
      padding: EdgeInsets.symmetric(
        vertical: 18.0.s,
        horizontal: 16.0.s,
      ),
      child: Opacity(
        opacity: 0.3, // For now, this feature is listed as "Coming Soon"
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              textAlign: TextAlign.center,
              title,
              style: context.theme.appTextThemes.caption2.copyWith(
                color: context.theme.appColors.secondaryText,
              ),
            ),
            SizedBox(height: 8.0.s),
            Text(
              textAlign: TextAlign.center,
              '$percentage%',
              style: context.theme.appTextThemes.headline2.copyWith(
                color: context.theme.appColors.sharkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard();

  @override
  Widget build(BuildContext context) {
    return _IonCard(
      child: Column(
        spacing: 8.0.s,
        children: [
          Opacity(
            opacity: 0.3,
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6.0.s,
                  children: [
                    Assets.svg.iconCreatecoinNewcoin.icon(
                      size: 16.0.s,
                      color: context.theme.appColors.sharkText,
                    ),
                    Text(
                      context.i18n.invite_friends_earnings_title,
                      style: context.theme.appTextThemes.subtitle3.copyWith(
                        color: context.theme.appColors.sharkText,
                      ),
                    ),
                  ],
                ),
                Text(
                  '0.00 ION',
                  style: context.theme.appTextThemes.headline2.copyWith(
                    color: context.theme.appColors.primaryText,
                  ),
                ),
                Text(
                  '~ 0.00 USD',
                  style: context.theme.appTextThemes.caption2.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const _ComingSoon(),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.appColors.onPrimaryAccent,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
      ),
      height: 28.0.s,
      width: 248.0.s,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6.0.s,
        children: [
          Assets.svg.iconBlockTime.icon(size: 12.0.s),
          Text(
            context.i18n.coming_soon_label,
            style: context.theme.appTextThemes.body2.copyWith(
              color: context.theme.appColors.primaryAccent,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SummaryItemType {
  totalReferrals,
  upgrades,
  deFi,
  ads,
}

extension on _SummaryItemType {
  String toText(BuildContext context) => switch (this) {
        _SummaryItemType.totalReferrals => context.i18n.invite_friends_summary_referrals_text,
        _SummaryItemType.upgrades => context.i18n.invite_friends_summary_upgrades_text,
        _SummaryItemType.deFi => context.i18n.invite_friends_summary_defi_text,
        _SummaryItemType.ads => context.i18n.invite_friends_summary_ads_text,
      };
}

typedef _ReferralSummaryItem = ({
  String iconPath,
  _SummaryItemType type,
  int value,
});

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.userSocialProfile});

  final AsyncValue<UserSocialProfileData> userSocialProfile;

  int _getReferralCount() {
    if (!userSocialProfile.hasValue) {
      return 0;
    }

    return userSocialProfile.value?.referralCount ?? 0;
  }

  List<_ReferralSummaryItem> get items => [
        (
          iconPath: Assets.svg.iconProfileUsertab,
          type: _SummaryItemType.totalReferrals,
          value: _getReferralCount(),
        ),
        (
          iconPath: Assets.svg.iconPostVerifyaccount,
          type: _SummaryItemType.upgrades,
          value: 0,
        ),
        (
          iconPath: Assets.svg.iconInviteDefi,
          type: _SummaryItemType.deFi,
          value: 0,
        ),
        (
          iconPath: Assets.svg.iconInviteAds,
          type: _SummaryItemType.ads,
          value: 0,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return _IonCard(
      padding: EdgeInsets.symmetric(
        vertical: 21.5.s,
        horizontal: 16.0.s,
      ),
      child: Column(
        spacing: 10.0.s,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8.0.s,
              children: [
                Row(
                  spacing: 6.0.s,
                  children: [
                    items[index].iconPath.icon(
                          size: 16.0.s,
                          color: context.theme.appColors.onTertiaryBackground,
                        ),
                    Text(
                      items[index].type.toText(context),
                      style: context.theme.appTextThemes.subtitle3.copyWith(
                        color: context.theme.appColors.sharkText,
                      ),
                    ),
                  ],
                ),
                Text(
                  items[index].value.toString(),
                  style: context.theme.appTextThemes.subtitle3.copyWith(
                    color: context.theme.appColors.sharkText,
                  ),
                ),
              ],
            ),
            if (index + 1 < items.length)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(0),
                      context.theme.appColors.onTertiaryFill,
                      Colors.white.withAlpha(0),
                    ],
                  ),
                ),
                child: SizedBox(
                  height: 0.5.s,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReferralCodeCard extends HookWidget {
  const _ReferralCodeCard({required this.referralCode});
  final String referralCode;

  @override
  Widget build(BuildContext context) {
    final isCopied = useState<bool>(false);
    final tooltipLeftPosition = useState<double>(0);
    final tooltipTopPosition = useState<double>(0);

    final copyIconWidth = 16.0.s;

    return _IonCard(
      padding: EdgeInsets.symmetric(horizontal: 60.0.s, vertical: 22.0.s),
      child: Column(
        spacing: 10.0.s,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6.0.s,
            children: [
              Assets.svg.iconRecoveryCode.icon(
                size: 20.0.s,
                color: context.theme.appColors.secondaryText,
              ),
              Text(
                context.i18n.invite_friends_referral_code_label,
                style: context.theme.appTextThemes.subtitle3.copyWith(
                  color: context.theme.appColors.onTertiaryBackground,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: referralCode));

              isCopied.value = true;

              await Future<void>.delayed(const Duration(seconds: 3)).then((_) {
                isCopied.value = false;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4.0.s,
              children: [
                Text(
                  referralCode,
                  style: context.theme.appTextThemes.subtitle.copyWith(
                    color: context.theme.appColors.primaryText,
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Assets.svg.iconBlockCopyBlue.icon(
                      size: copyIconWidth,
                      color: context.theme.appColors.primaryAccent,
                    ),
                    PositionedDirectional(
                      top: tooltipTopPosition.value,
                      start: tooltipLeftPosition.value,
                      child: Opacity(
                        opacity: isCopied.value ? 1 : 0,
                        child: CopiedTooltip(
                          onLayout: (Size size) {
                            tooltipTopPosition.value = -size.height - 11.0.s;
                            tooltipLeftPosition.value = (copyIconWidth - size.width) / 2;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IonCard extends StatelessWidget {
  const _IonCard({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.appColors.primaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      child: Padding(
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: 16.0.s,
              vertical: 16.0.s,
            ),
        child: child,
      ),
    );
  }
}
