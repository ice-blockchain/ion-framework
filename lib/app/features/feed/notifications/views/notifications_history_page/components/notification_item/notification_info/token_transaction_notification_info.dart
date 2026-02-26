// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_loading.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/notification_info_text.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/components/notification_item/notification_info/username_text_span.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_tap_gesture_recognizer.dart';
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
    final actionAuthorPubkey = notification.eventReference.masterPubkey;
    final actionEntity = _getTokenActionEntity(ref);
    final tokenOwnerPubkey = actionEntity?.data.definitionReference.masterPubkey;
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    final isCurrentUserTokenAction = currentPubkey == tokenOwnerPubkey;

    final actionAuthorData = ref.watch(userPreviewDataProvider(actionAuthorPubkey)).valueOrNull;
    final actionAuthorRecognizer = useTapGestureRecognizer(
      onTap: () => ProfileRoute(pubkey: actionAuthorPubkey).push<void>(context),
    );
    final tokenOwnerData = tokenOwnerPubkey != null
        ? ref.watch(userPreviewDataProvider(tokenOwnerPubkey)).valueOrNull
        : null;
    final tokenOwnerRecognizer = useTapGestureRecognizer(
      onTap: () => tokenOwnerPubkey != null
          ? ProfileRoute(pubkey: tokenOwnerPubkey).push<void>(context)
          : null,
    );

    if (actionAuthorData == null || tokenOwnerData == null || actionEntity == null) {
      return const NotificationInfoLoading();
    }

    final description = switch (actionEntity.data.type) {
      CommunityTokenActionType.buy => switch (actionEntity.data.kind) {
          ModifiablePostEntity.kind || PostEntity.kind => isCurrentUserTokenAction
              ? context.i18n.notifications_token_transaction_buy_post
              : context.i18n.notifications_token_transaction_buy_other_user_post,
          ArticleEntity.kind => isCurrentUserTokenAction
              ? context.i18n.notifications_token_transaction_buy_article
              : context.i18n.notifications_token_transaction_buy_other_user_article,
          UserMetadataEntity.kind => isCurrentUserTokenAction
              ? context.i18n.notifications_token_transaction_buy_creator
              : context.i18n.notifications_token_transaction_buy_other_user_creator,
          _ => '',
        },
      CommunityTokenActionType.sell => switch (actionEntity.data.kind) {
          ModifiablePostEntity.kind || PostEntity.kind => isCurrentUserTokenAction
              ? context.i18n.notifications_token_transaction_sell_post
              : context.i18n.notifications_token_transaction_sell_other_user_post,
          ArticleEntity.kind => isCurrentUserTokenAction
              ? context.i18n.notifications_token_transaction_sell_article
              : context.i18n.notifications_token_transaction_sell_other_user_article,
          UserMetadataEntity.kind => isCurrentUserTokenAction
              ? context.i18n.notifications_token_transaction_sell_creator
              : context.i18n.notifications_token_transaction_sell_other_user_creator,
          _ => '',
        }
    };

    final textSpan = replaceString(
      description,
      RegExp(
        '${tagRegex('username').pattern}|${tagRegex('relatedUsername').pattern}|${tagRegex('green', isSingular: false).pattern}|${tagRegex('red', isSingular: false).pattern}|${tagRegex('amount').pattern}',
      ),
      (match, index) {
        if (match.namedGroup('username') != null) {
          return buildUsernameTextSpan(
            context,
            userData: actionAuthorData.data,
            recognizer: actionAuthorRecognizer,
          );
        } else if (match.namedGroup('relatedUsername') != null) {
          return buildUsernameTextSpan(
            context,
            userData: tokenOwnerData.data,
            recognizer: tokenOwnerRecognizer,
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
          if (actionEntity case CommunityTokenActionEntity(:final data)) {
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

  CommunityTokenActionEntity? _getTokenActionEntity(WidgetRef ref) {
    final entity = ref.watch(
      ionConnectSyncEntityWithCountersProvider(
        eventReference: notification.eventReference,
      ),
    );
    if (entity is CommunityTokenActionEntity) {
      return entity;
    }
    return null;
  }
}
