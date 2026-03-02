// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/utils/date.dart';

class NotificationInfoText extends ConsumerWidget {
  const NotificationInfoText({
    required this.textSpan,
    required this.timestamp,
    this.showTodayLabel = true,
    super.key,
  });

  final TextSpan textSpan;

  final DateTime timestamp;

  final bool showTodayLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final time = showTodayLabel && isSameDay(timestamp, DateTime.now())
        ? context.i18n.date_today
        : formatShortTimestamp(timestamp, locale: locale, context: context);

    return Text.rich(
      TextSpan(
        children: [
          textSpan,
          TextSpan(
            children: [const TextSpan(text: ' • '), TextSpan(text: time)],
            style: context.theme.appTextThemes.body2.copyWith(
              color: context.theme.appColors.tertiaryText,
            ),
          ),
        ],
      ),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.theme.appTextThemes.body2.copyWith(
        color: context.theme.appColors.primaryText,
      ),
    );
  }
}
