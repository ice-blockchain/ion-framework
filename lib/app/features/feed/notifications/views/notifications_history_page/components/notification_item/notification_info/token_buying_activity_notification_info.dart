// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_buying_activity_response.f.dart';
import 'package:ion/l10n/i10n.dart';

class TokenBuyingActivityNotificationInfo extends ConsumerWidget {
  const TokenBuyingActivityNotificationInfo({
    required this.entity,
    required this.timestamp,
    super.key,
  });

  final TokenBuyingActivityResponseEntity entity;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticker = entity.data.tokenAction.data.tokenTicker;
    final description = context.i18n.notifications_token_buying_activity_increased;

    final textSpan = replaceString(
      description,
      RegExp(
        '${tagRegex('bold', isSingular: false).pattern}|${tagRegex('green', isSingular: false).pattern}|${tagRegex('ticker').pattern}',
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
        _ when match.namedGroup('ticker') != null => TextSpan(
            text: ticker,
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
}
