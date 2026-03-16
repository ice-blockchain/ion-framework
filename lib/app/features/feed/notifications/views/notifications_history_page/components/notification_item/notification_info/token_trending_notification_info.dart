// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/tokens_global_stat_response.f.dart';
import 'package:ion/l10n/i10n.dart';

class TokenTrendingNotificationInfo extends ConsumerWidget {
  const TokenTrendingNotificationInfo({
    required this.entity,
    required this.timestamp,
    super.key,
  });

  final TokenGlobalStatResponseEntity entity;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticker = entity.data.tokenAction.data.tokenTicker;
    final description = context.i18n.notifications_token_trending;

    final textSpan = replaceString(
      description,
      tagRegex('ticker'),
      (match, index) => TextSpan(
        text: ticker,
        style:
            context.theme.appTextThemes.body2.copyWith(color: context.theme.appColors.primaryText),
      ),
    );

    return NotificationInfoText(
      textSpan: textSpan,
      timestamp: timestamp,
    );
  }
}
