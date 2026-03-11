// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_price_change_response.f.dart';
import 'package:ion/l10n/i10n.dart';

class TokenPriceChangeNotificationInfo extends ConsumerWidget {
  const TokenPriceChangeNotificationInfo({
    required this.entity,
    required this.timestamp,
    super.key,
  });

  final TokenPriceChangeResponseEntity entity;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = _computePriceChangePercent();
    final description = context.i18n.notifications_token_value_increased;

    final textSpan = replaceString(
      description,
      RegExp(
        '${tagRegex('bold', isSingular: false).pattern}|${tagRegex('green', isSingular: false).pattern}|${tagRegex('value').pattern}',
      ),
      (match, index) => switch (true) {
        _ when match.namedGroup('bold') != null => TextSpan(
            text: match.namedGroup('bold'),
            style: context.theme.appTextThemes.body2.copyWith(fontWeight: FontWeight.bold),
          ),
        _ when match.namedGroup('green') != null => TextSpan(
            text: match.namedGroup('green'),
            style:
                context.theme.appTextThemes.body2.copyWith(color: context.theme.appColors.success),
          ),
        _ when match.namedGroup('value') != null => TextSpan(
            text: value.toString(),
            style: context.theme.appTextThemes.body2
                .copyWith(color: context.theme.appColors.primaryText),
          ),
        _ => const TextSpan(text: ''),
      },
    );

    return NotificationInfoText(
      textSpan: textSpan,
      timestamp: timestamp,
    );
  }

  int _computePriceChangePercent() {
    final actions = entity.data.actions;
    final fallback = entity.data.request.data.params.deltaPercentage;

    if (actions.length < 2) return fallback;

    final firstUsd = actions.first.data.getUsdAmount()?.value;
    final lastUsd = actions.last.data.getUsdAmount()?.value;

    if (firstUsd == null || lastUsd == null || firstUsd == 0) return fallback;

    final diff = ((lastUsd - firstUsd) / firstUsd * 100).round();
    return diff > 0 ? diff : fallback;
  }
}
