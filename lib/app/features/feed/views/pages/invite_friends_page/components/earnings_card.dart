// SPDX-License-Identifier: ice License 1.0

part of '../invite_friends_page.dart';

class _EarningsCard extends StatelessWidget {
  const _EarningsCard();

  @override
  Widget build(BuildContext context) {
    return _IonCard(
      child: Column(
        spacing: 8.0.s,
        children: [
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6.0.s,
                children: [
                  Assets.svg.iconCreatecoinNewcoin.icon(
                    size: 16.0.s,
                    color: context.theme.appColors.sharkText.withValues(alpha: 0.3),
                  ),
                  Text(
                    context.i18n.invite_friends_earnings_title,
                    style: context.theme.appTextThemes.subtitle3.copyWith(
                      color: context.theme.appColors.sharkText.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              Text(
                '0.00 ION',
                style: context.theme.appTextThemes.headline2.copyWith(
                  color: context.theme.appColors.primaryText.withValues(alpha: 0.3),
                ),
              ),
              Text(
                '~ 0.00 USD',
                style: context.theme.appTextThemes.caption2.copyWith(
                  color: context.theme.appColors.secondaryText.withValues(alpha: 0.3),
                ),
              ),
            ],
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
