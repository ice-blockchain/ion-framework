// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/notification_type_phrase.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/l10n/i10n.dart';

// TODO: refactor - extract description building from the model, create separate widgets per use case
class NotificationInfo extends HookConsumerWidget {
  const NotificationInfo({
    required this.notification,
    super.key,
  });

  final IonNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);

    final relatedEntity = _getRelatedEntity(ref, notification: notification);
    final eventType = _getEventType(ref, notification: notification);
    final isAuthor = _getIsAuthor(ref, notification: notification);

    final pubkeys = [...notification.pubkeys, _getRelatedEntityPubkey(relatedEntity)].nonNulls;

    final userDatas = pubkeys.take(pubkeys.length == 2 ? 2 : 1).map((pubkey) {
      return ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    }).toList();

    if (userDatas.contains(null)) {
      return const _Loading();
    }

    final description = switch (notification) {
      final LikesIonNotification notification => () {
          final typePhrase = getNotificationTypePhrase(
            context.i18n,
            NotificationTypeContext.liked,
            eventType ?? NotificationEventType.post,
          );
          return notification.getDescription(context, typePhrase);
        }(),
      final CommentIonNotification notification => () {
          final typeContext = switch (notification.type) {
            CommentIonNotificationType.reply =>
              isAuthor ? NotificationTypeContext.replyToYour : NotificationTypeContext.replyToThe,
            CommentIonNotificationType.quote => relatedEntity is CommunityTokenDefinitionEntity
                ? (_isOwnToken(ref, tokenDefinition: relatedEntity)
                    ? NotificationTypeContext.share
                    : NotificationTypeContext.shareThe)
                : (isAuthor ? NotificationTypeContext.share : NotificationTypeContext.shareThe),
            CommentIonNotificationType.repost => NotificationTypeContext.repost,
          };
          final typePhrase = getNotificationTypePhrase(
            context.i18n,
            typeContext,
            eventType ?? NotificationEventType.post,
          );
          return notification.getDescription(context, typePhrase, isAuthor);
        }(),
      final ContentIonNotification notification => notification.getDescription(context),
      final MentionIonNotification notification => notification.getDescription(context),
      final TokenLaunchIonNotification notification =>
        notification.getDescription(context, relatedEntity),
      final TokenTransactionIonNotification notification => notification.getDescription(
          context,
          relatedEntity,
          _isCurrentUserTokenTransaction(ref, entity: relatedEntity),
        ),
      _ => notification.getDescription(context)
    };

    final newTapRecognizers = <TapGestureRecognizer>[];
    final textSpan = replaceString(
      description,
      RegExp(
        '${tagRegex('username').pattern}|${tagRegex('purple', isSingular: false).pattern}|${tagRegex('red', isSingular: false).pattern}|${tagRegex('green', isSingular: false).pattern}|${tagRegex('amount').pattern}',
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
          newTapRecognizers.add(recognizer);
          return TextSpan(
            text: userData.data.trimmedDisplayName.isEmpty
                ? userData.data.name
                : userData.data.trimmedDisplayName,
            style: context.theme.appTextThemes.body.copyWith(
              color: context.theme.appColors.primaryText,
            ),
            recognizer: recognizer,
          );
        } else if (match.namedGroup('purple') != null) {
          return TextSpan(
            text: match.namedGroup('purple'),
            style: context.theme.appTextThemes.body.copyWith(color: context.theme.appColors.purple),
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
        } else if (match.namedGroup('amount') != null &&
            relatedEntity is CommunityTokenActionEntity) {
          final coins = relatedEntity.data.getTokenAmount()?.value ?? 0.0;
          return TextSpan(
            text: coins >= 1 ? formatCount(coins.toInt()) : coins.toString(),
            style: context.theme.appTextThemes.body
                .copyWith(color: context.theme.appColors.primaryText),
          );
        }
        return const TextSpan(text: '');
      },
    );

    useEffect(
      () {
        return () {
          for (final recognizer in newTapRecognizers) {
            recognizer.dispose();
          }
        };
      },
      [newTapRecognizers],
    );

    return Text.rich(
      TextSpan(children: [textSpan, _getDateTextSpan(context, locale: locale)]),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.theme.appTextThemes.body2.copyWith(
        color: context.theme.appColors.primaryText,
      ),
    );
  }

  String? _getRelatedEntityPubkey(IonConnectEntity? relatedEntity) {
    return switch (relatedEntity) {
      CommunityTokenActionEntity() => relatedEntity.data.definitionReference.masterPubkey,
      _ => relatedEntity?.masterPubkey,
    };
  }

  TextSpan _getDateTextSpan(BuildContext context, {required Locale locale}) {
    final isToday = isSameDay(notification.timestamp, DateTime.now());
    final time = notification is CommentIonNotification
        ? formatShortTimestamp(notification.timestamp, locale: locale, context: context)
        : isToday
            ? context.i18n.date_today
            : formatShortTimestamp(notification.timestamp, locale: locale, context: context);
    return TextSpan(
      children: [const TextSpan(text: ' • '), TextSpan(text: time)],
      style: context.theme.appTextThemes.body2.copyWith(
        color: context.theme.appColors.tertiaryText,
      ),
    );
  }

  NotificationEventType? _getEventType(WidgetRef ref, {required IonNotification notification}) {
    final relatedEntity = _getRelatedEntity(ref, notification: notification);

    return switch (relatedEntity) {
      ModifiablePostEntity() when relatedEntity.isStory => NotificationEventType.story,
      ModifiablePostEntity(:final data) when data.parentEvent != null =>
        NotificationEventType.comment,
      ModifiablePostEntity() => NotificationEventType.post,
      ArticleEntity() => NotificationEventType.article,
      _ => null,
    };
  }

  bool _getIsAuthor(WidgetRef ref, {required IonNotification notification}) {
    final relatedEntity = _getRelatedEntity(ref, notification: notification);

    if (relatedEntity == null) return false;

    final authorPubkey = relatedEntity.masterPubkey;
    final currentUserPubkey = ref.read(currentPubkeySelectorProvider);

    return authorPubkey == currentUserPubkey;
  }

  bool _isOwnToken(
    WidgetRef ref, {
    required CommunityTokenDefinitionEntity tokenDefinition,
  }) {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentPubkey == null) return false;

    final data = tokenDefinition.data;
    return data is CommunityTokenDefinitionIon && data.eventReference.masterPubkey == currentPubkey;
  }

  bool _isCurrentUserTokenTransaction(
    WidgetRef ref, {
    required IonConnectEntity? entity,
  }) {
    if (entity is! CommunityTokenActionEntity) return false;

    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    if (currentPubkey == null) return false;

    return entity.data.definitionReference.masterPubkey == currentPubkey;
  }

  IonConnectEntity? _getRelatedEntity(WidgetRef ref, {required IonNotification notification}) {
    final eventReference = switch (notification) {
      CommentIonNotification() => notification.eventReference,
      LikesIonNotification() => notification.eventReference,
      MentionIonNotification() => notification.eventReference,
      TokenLaunchIonNotification() => notification.eventReference,
      TokenTransactionIonNotification() => notification.eventReference,
      _ => null,
    };

    if (eventReference == null) {
      return null;
    }

    final entity =
        ref.watch(ionConnectSyncEntityWithCountersProvider(eventReference: eventReference));

    if (entity == null) {
      return null;
    }

    if (notification is LikesIonNotification ||
        notification is MentionIonNotification ||
        notification is TokenTransactionIonNotification) {
      return entity;
    }

    if (notification is TokenLaunchIonNotification && entity is CommunityTokenDefinitionEntity) {
      final data = entity.data;
      if (data is CommunityTokenDefinitionIon) {
        return ref
            .watch(ionConnectSyncEntityWithCountersProvider(eventReference: data.eventReference));
      }
    }

    if (notification is CommentIonNotification) {
      final relatedEventReference = switch (entity) {
        GenericRepostEntity() => entity.data.eventReference,
        ModifiablePostEntity() =>
          entity.data.parentEvent?.eventReference ?? entity.data.quotedEvent?.eventReference,
        _ => null,
      };

      if (relatedEventReference != null) {
        return ref
            .watch(ionConnectSyncEntityWithCountersProvider(eventReference: relatedEventReference));
      }
    }

    return null;
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          width: 240.0.s,
          height: 19.0.s,
        ),
      ),
    );
  }
}
