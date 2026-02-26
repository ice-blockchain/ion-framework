// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/username_text_span.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_tap_gesture_recognizers.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/l10n/i10n.dart';

class TokenTransactionNotificationInfo extends HookConsumerWidget {
  const TokenTransactionNotificationInfo({
    required this.notification,
    super.key,
  });

  final TokenTransactionIonNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubkeys = notification.pubkeys;
    final recognizers = useTapGestureRecognizers();
    final relatedEntity = _getRelatedEntity(ref);
    final isCurrentUserTokenTransaction = _isCurrentUserTokenTransaction(ref);

    final userDatas = pubkeys.map((pubkey) {
      return ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    }).toList();

    if (userDatas.contains(null)) {
      return const SizedBox.shrink();
    }

    final description = switch (relatedEntity) {
      CommunityTokenActionEntity(:final data) => switch (data.type) {
          CommunityTokenActionType.buy => switch (data.kind) {
              ModifiablePostEntity.kind || PostEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_buy_post
                  : context.i18n.notifications_token_transaction_buy_other_user_post,
              ArticleEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_buy_article
                  : context.i18n.notifications_token_transaction_buy_other_user_article,
              UserMetadataEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_buy_creator
                  : context.i18n.notifications_token_transaction_buy_other_user_creator,
              _ => '',
            },
          CommunityTokenActionType.sell => switch (data.kind) {
              ModifiablePostEntity.kind || PostEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_sell_post
                  : context.i18n.notifications_token_transaction_sell_other_user_post,
              ArticleEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_sell_article
                  : context.i18n.notifications_token_transaction_sell_other_user_article,
              UserMetadataEntity.kind => isCurrentUserTokenTransaction
                  ? context.i18n.notifications_token_transaction_sell_creator
                  : context.i18n.notifications_token_transaction_sell_other_user_creator,
              _ => '',
            }
        },
      _ => ''
    };

    final textSpan = replaceString(
      description,
      RegExp(
        '${tagRegex('username').pattern}|${tagRegex('green', isSingular: false).pattern}|${tagRegex('red', isSingular: false).pattern}|${tagRegex('amount').pattern}',
      ),
      (match, index) {
        if (match.namedGroup('username') != null) {
          final pubkey = pubkeys.elementAtOrNull(index);
          final userData = userDatas.elementAtOrNull(index);
          if (pubkey == null || userData == null) {
            return const TextSpan(text: '');
          }
          final recognizer = TapGestureRecognizer()
            ..onTap = () => ProfileRoute(pubkey: pubkey).push<void>(context);
          recognizers.add(recognizer);
          final displayName = userData.data.trimmedDisplayName.isEmpty
              ? userData.data.name
              : userData.data.trimmedDisplayName;
          return buildUsernameTextSpan(
            context,
            displayName: displayName,
            recognizer: recognizer,
          );
        } else if (match.namedGroup('green') != null) {
          return TextSpan(
            text: match.namedGroup('green'),
            style:
                context.theme.appTextThemes.body.copyWith(color: context.theme.appColors.success),
          );
        } else if (match.namedGroup('red') != null) {
          return TextSpan(
            text: match.namedGroup('red'),
            style: context.theme.appTextThemes.body
                .copyWith(color: context.theme.appColors.attentionRed),
          );
        } else if (match.namedGroup('amount') != null) {
          if (relatedEntity case CommunityTokenActionEntity(:final data)) {
            final coins = data.getTokenAmount()?.value ?? 0.0;
            return TextSpan(
              text: coins >= 1 ? formatCount(coins.toInt()) : coins.toString(),
              style: context.theme.appTextThemes.body
                  .copyWith(color: context.theme.appColors.primaryText),
            );
          }
        }
        return const TextSpan(text: '');
      },
    );

    return NotificationInfoText(
      textSpan: textSpan,
      timestamp: notification.timestamp,
    );
  }

  bool _isCurrentUserTokenTransaction(WidgetRef ref) {
    final relatedEntity = _getRelatedEntity(ref);
    if (relatedEntity is! CommunityTokenActionEntity) return false;

    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentPubkey == null) return false;

    return relatedEntity.data.definitionReference.masterPubkey == currentPubkey;
  }

  IonConnectEntity? _getRelatedEntity(WidgetRef ref) {
    final eventReference = notification.eventReference;

    final entity = ref.watch(
      ionConnectSyncEntityWithCountersProvider(
        eventReference: eventReference,
      ),
    );
    return entity;
  }
}
