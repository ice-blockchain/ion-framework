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
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_tap_gesture_recognizer.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/l10n/i10n.dart';

class TokenLaunchNotificationInfo extends HookConsumerWidget {
  const TokenLaunchNotificationInfo({
    required this.notification,
    super.key,
  });

  final TokenLaunchIonNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchDefinitionAuthorPubkey = notification.eventReference.masterPubkey;
    final relatedEntity = _getRelatedEntity(ref);
    final tokenOwnerPubkey = relatedEntity?.masterPubkey;
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    final isCurrentUserTokenLaunched = tokenOwnerPubkey == currentPubkey;

    final launchDefinitionAuthorData =
        ref.watch(userPreviewDataProvider(launchDefinitionAuthorPubkey)).valueOrNull;
    final launchDefinitionAuthorRecognizer = useTapGestureRecognizer(
      onTap: () => ProfileRoute(pubkey: launchDefinitionAuthorPubkey).push<void>(context),
    );
    final tokenOwnerData = tokenOwnerPubkey != null
        ? ref.watch(userPreviewDataProvider(tokenOwnerPubkey)).valueOrNull
        : null;
    final tokenOwnerRecognizer = useTapGestureRecognizer(
      onTap: () => tokenOwnerPubkey != null
          ? ProfileRoute(pubkey: tokenOwnerPubkey).push<void>(context)
          : null,
    );

    if (launchDefinitionAuthorData == null || tokenOwnerData == null || relatedEntity == null) {
      return const NotificationInfoLoading();
    }

    final description = switch (relatedEntity) {
      ModifiablePostEntity() || PostEntity() => isCurrentUserTokenLaunched
          ? context.i18n.notifications_token_launched_post
          : context.i18n.notifications_token_launched_other_user_post,
      ArticleEntity() => isCurrentUserTokenLaunched
          ? context.i18n.notifications_token_launched_article
          : context.i18n.notifications_token_launched_other_user_article,
      UserMetadataEntity() => isCurrentUserTokenLaunched
          ? context.i18n.notifications_token_launched_creator
          : context.i18n.notifications_token_launched_other_user_creator,
      _ => ''
    };

    final textSpan = replaceString(
      description,
      RegExp(
        '${tagRegex('username').pattern}|${tagRegex('relatedUsername').pattern}|${tagRegex('purple', isSingular: false).pattern}',
      ),
      (match, index) {
        if (match.namedGroup('username') != null) {
          return buildUsernameTextSpan(
            context,
            userData: launchDefinitionAuthorData.data,
            recognizer: launchDefinitionAuthorRecognizer,
          );
        } else if (match.namedGroup('relatedUsername') != null) {
          return buildUsernameTextSpan(
            context,
            userData: tokenOwnerData.data,
            recognizer: tokenOwnerRecognizer,
          );
        } else if (match.namedGroup('purple') != null) {
          return TextSpan(
            text: match.namedGroup('purple'),
            style: context.theme.appTextThemes.body.copyWith(color: context.theme.appColors.purple),
          );
        }
        return const TextSpan(text: '');
      },
    );

    return NotificationInfoText(
      textSpan: textSpan,
      timestamp: notification.timestamp,
    );
  }

  IonConnectEntity? _getRelatedEntity(WidgetRef ref) {
    final entity = ref.watch(
      ionConnectSyncEntityWithCountersProvider(
        eventReference: notification.eventReference,
      ),
    );
    if (entity == null) return null;

    if (entity is CommunityTokenDefinitionEntity) {
      final data = entity.data;
      if (data is CommunityTokenDefinitionIon) {
        return ref.watch(
          ionConnectSyncEntityWithCountersProvider(
            eventReference: data.eventReference,
          ),
        );
      }
    }

    return null;
  }
}
