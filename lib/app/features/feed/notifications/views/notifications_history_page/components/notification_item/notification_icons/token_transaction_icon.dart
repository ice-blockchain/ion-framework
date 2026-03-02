// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_icons/outlined_notification_icon.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenTransactionIcon extends ConsumerWidget {
  const TokenTransactionIcon({required this.size, required this.eventReference, super.key});

  final double size;
  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAction =
        ref.watch(ionConnectEntityWithCountersProvider(eventReference: eventReference)).valueOrNull;

    if (tokenAction is! CommunityTokenActionEntity) {
      return const SizedBox.shrink();
    }

    return OutlinedNotificationIcon(
      size: size,
      asset: switch (tokenAction.data.type) {
        CommunityTokenActionType.buy => Assets.svg.iconButtonReceive,
        CommunityTokenActionType.sell => Assets.svg.iconButtonSend,
      },
      backgroundColor: switch (tokenAction.data.type) {
        CommunityTokenActionType.buy => context.theme.appColors.success,
        CommunityTokenActionType.sell => context.theme.appColors.attentionRed,
      },
    );
  }
}
