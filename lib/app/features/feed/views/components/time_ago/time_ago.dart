// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/utils/date.dart';

enum TimestampFormat { short, detailed, compact }

class TimeAgo extends ConsumerWidget {
  const TimeAgo({
    required this.time,
    this.timeFormat = TimestampFormat.short,
    super.key,
    this.style,
  });

  final DateTime time;
  final TimestampFormat timeFormat;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final formattedTime = switch (timeFormat) {
      TimestampFormat.detailed => formatDetailedTimestamp(time, locale: locale),
      TimestampFormat.compact => formatCompactTimestamp(time, locale: locale),
      TimestampFormat.short => formatShortTimestamp(time, locale: locale, context: context),
    };

    return Text(
      formattedTime,
      style: style ??
          context.theme.appTextThemes.caption.copyWith(
            color: context.theme.appColors.tertiaryText,
          ),
    );
  }
}
