// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/timeline_item_data.dart';
import 'package:ion/app/features/wallets/views/components/timeline/timeline_separator.dart';
import 'package:ion/generated/assets.gen.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    required this.isLast,
    required this.data,
    super.key,
    this.isNextDone = false,
  });

  final bool isLast;
  final TimelineItemData data;
  final bool? isNextDone;

  static double get separatorWidth => 1.0.s;

  static double get separatorHeight => 9.0.s;

  @override
  Widget build(BuildContext context) {
    final icon = data.isFailed
        ? Assets.svg.iconStepsCheckFailed
        : data.isDone
            ? Assets.svg.iconStepsCheckActive
            : Assets.svg.iconStepsCheckInactive;

    final color = data.isFailed
        ? context.theme.appColors.attentionRed
        : data.isDone
            ? context.theme.appColors.success
            : context.theme.appColors.tertiaryText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Center(
              child: SvgPicture.asset(
                icon,
                width: 16.0.s,
                height: 16.0.s,
                colorFilter: ColorFilter.mode(
                  color,
                  BlendMode.srcIn,
                ),
              ),
            ),
            if (!isLast)
              TimelineSeparator(
                color: isNextDone != null && isNextDone!
                    ? context.theme.appColors.success
                    : context.theme.appColors.tertiaryText,
              ),
          ],
        ),
        SizedBox(width: 8.0.s),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: context.theme.appTextThemes.caption.copyWith(
                    color: data.isDone || data.isFailed
                        ? context.theme.appColors.primaryText
                        : context.theme.appColors.tertiaryText,
                  ),
                ),
              ),
              if (data.date != null)
                Text(
                  DateFormat('dd.MM.yyyy HH:mm:ss').format(data.date!.toLocal()),
                  style: context.theme.appTextThemes.caption3.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
