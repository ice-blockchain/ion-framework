// SPDX-License-Identifier: ice License 1.0

part of '../invite_friends_page.dart';

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
