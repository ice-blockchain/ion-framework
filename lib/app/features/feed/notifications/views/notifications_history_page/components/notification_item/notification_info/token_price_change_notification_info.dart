// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_price_change_response.f.dart';
import 'package:ion/l10n/i10n.dart';

class TokenPriceChangeNotificationInfo extends HookConsumerWidget {
  const TokenPriceChangeNotificationInfo({
    required this.entity,
    required this.timestamp,
    super.key,
  });

  final TokenPriceChangeResponseEntity entity;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = useMemoized(entity.data.computePriceChangePercent);
    final descriptionTemplate = context.i18n.notifications_token_value_increased;

    // Updating the [:value] separately to avoid conflicts with the wrapping [:green] tag.
    final description = descriptionTemplate.replaceAll('[:value]', value.toString());

    final textSpan = replaceString(
      description,
      RegExp(
        '${tagRegex('bold', isSingular: false).pattern}|${tagRegex('green', isSingular: false).pattern}',
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
        _ => const TextSpan(text: ''),
      },
    );

    return NotificationInfoText(
      textSpan: textSpan,
      timestamp: timestamp,
    );
  }
}
