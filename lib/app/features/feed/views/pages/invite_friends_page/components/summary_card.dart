// SPDX-License-Identifier: ice License 1.0

part of '../invite_friends_page.dart';

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this._userSocialProfile);

  final UserSocialProfileData? _userSocialProfile;

  int _getReferralCount() {
    if (_userSocialProfile == null) {
      return 0;
    }

    return _userSocialProfile.referralCount ?? 0;
  }

  List<ReferralSummaryItem> get items => [
        (
          iconPath: Assets.svg.iconProfileUsertab,
          type: SummaryItemType.totalReferrals,
          value: _getReferralCount(),
        ),
        (
          iconPath: Assets.svg.iconPostVerifyaccount,
          type: SummaryItemType.upgrades,
          value: 0,
        ),
        (
          iconPath: Assets.svg.iconInviteDefi,
          type: SummaryItemType.deFi,
          value: 0,
        ),
        (
          iconPath: Assets.svg.iconInviteAds,
          type: SummaryItemType.ads,
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

  final ReferralSummaryItem item;

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
