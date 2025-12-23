// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/num.dart';

class PollResultItem extends HookWidget {
  const PollResultItem({
    required this.text,
    required this.votes,
    required this.totalVotes,
    this.isSelected = false,
    this.accentTheme = false,
    super.key,
  });

  final String text;
  final int votes;
  final int totalVotes;
  final bool isSelected;
  final bool accentTheme;

  String _getPercentageString(double percentage) {
    final result = formatDouble(percentage, maximumFractionDigits: 1, minimumFractionDigits: 0);

    return '$result%';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = useMemoized(
      () {
        if (totalVotes == 0) return 0.0;
        return votes / totalVotes;
      },
      [votes, totalVotes],
    );
    final percentageValue = percentage * 100;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0.s),
      child: Stack(
        children: [
          // Background container
          Container(
            height: 34.0.s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0.s),
            ),
          ),

          // 0% progress indicator placeholder
          if (percentageValue < 1)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                height: 34.0.s,
                width: 4.0.s,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentTheme
                          ? context.theme.appColors.darkNight
                          : context.theme.appColors.primaryAccent.withValues(alpha: 0.3)
                      : accentTheme
                          ? context.theme.appColors.darkBlue
                          : context.theme.appColors.onTertiaryFill,
                  borderRadius: BorderRadius.circular(12.0.s),
                ),
              ),
            ),

          // Progress indicator
          if (percentageValue > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0.s),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  height: 34.0.s,
                  width:
                      (MediaQuery.sizeOf(context).width * percentage).clamp(4.0.s, double.infinity),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentTheme
                            ? context.theme.appColors.darkNight
                            : context.theme.appColors.primaryAccent.withValues(alpha: 0.3)
                        : accentTheme
                            ? context.theme.appColors.darkBlue
                            : context.theme.appColors.onTertiaryFill,
                    borderRadius: BorderRadius.circular(12.0.s),
                  ),
                ),
              ),
            ),

          // Text and percentage
          SizedBox(
            height: 34.0.s,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 12.0.s),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: context.theme.appTextThemes.caption2.copyWith(
                        color: accentTheme
                            ? context.theme.appColors.onPrimaryAccent
                            : context.theme.appColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _getPercentageString(percentageValue),
                    style: context.theme.appTextThemes.caption2.copyWith(
                      color: accentTheme
                          ? context.theme.appColors.onPrimaryAccent
                          : context.theme.appColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
