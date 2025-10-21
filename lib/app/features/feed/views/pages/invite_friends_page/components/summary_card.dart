// SPDX-License-Identifier: ice License 1.0

part of '../invite_friends_page.dart';

enum _SummaryItemType {
  totalReferrals,
  upgrades,
  deFi,
  ads;

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
          for (final item in items) ...[
            _SummaryItemRow(item: item),
            if (item != items.last) const _SummarySeparator(),
          ],
        ],
      ),
    );
  }
}

class _SummaryItemRow extends StatelessWidget {
  const _SummaryItemRow({required this.item});

  final _ReferralSummaryItem item;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.theme.appTextThemes.subtitle3.copyWith(
      color: context.theme.appColors.sharkText,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 8.0.s,
      children: [
        Row(
          spacing: 6.0.s,
          children: [
            item.iconPath.icon(
              size: 16.0.s,
              color: context.theme.appColors.onTertiaryBackground,
            ),
            Text(
              item.type.toText(context),
              style: textStyle,
            ),
          ],
        ),
        Text(
          item.value.toString(),
          style: textStyle,
        ),
      ],
    );
  }
}

class _SummarySeparator extends StatelessWidget {
  const _SummarySeparator();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    );
  }
}
