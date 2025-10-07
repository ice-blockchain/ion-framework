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
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/l10n/i10n.dart';

class NotificationInfo extends HookConsumerWidget {
  const NotificationInfo({
    required this.notification,
    super.key,
  });

  final IonNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final userDatas =
        notification.pubkeys.take(notification.pubkeys.length == 2 ? 2 : 1).map((pubkey) {
      return ref.watch(userMetadataProvider(pubkey)).valueOrNull;
    }).toList();

    final eventTypeLabel = _getEventTypeLabel(ref, notification: notification);
    final isAuthor = _getIsAuthor(ref, notification: notification);

    if (userDatas.contains(null)) {
      return const _Loading();
    }

    final description = switch (notification) {
      final LikesIonNotification notification =>
        notification.getDescription(context, eventTypeLabel),
      final CommentIonNotification notification =>
        notification.getDescription(context, eventTypeLabel, isAuthor),
      final ContentIonNotification notification => notification.getDescription(context),
      final MentionIonNotification notification =>
        notification.getDescription(context, eventTypeLabel),
      _ => notification.getDescription(context)
    };

    final newTapRecognizers = <TapGestureRecognizer>[];
    final textSpan = replaceString(
      description,
      tagRegex('username'),
      (String text, int index) {
        final pubkey = notification.pubkeys[index];
        final userData = userDatas[index];
        if (userData == null) {
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

  String _getEventTypeLabel(WidgetRef ref, {required IonNotification notification}) {
    final relatedEntity = _getRelatedEntity(ref, notification: notification);

    return switch (relatedEntity) {
      ModifiablePostEntity(:final data) when data.expiration != null =>
        ref.context.i18n.common_story,
      ModifiablePostEntity(:final data) when data.parentEvent != null =>
        ref.context.i18n.common_comment,
      ModifiablePostEntity() => ref.context.i18n.common_post,
      ArticleEntity() => ref.context.i18n.common_article,
      _ => '',
    };
  }

  bool _getIsAuthor(WidgetRef ref, {required IonNotification notification}) {
    final relatedEntity = _getRelatedEntity(ref, notification: notification);

    if (relatedEntity == null) return false;

    final authorPubkey = relatedEntity.masterPubkey;
    final currentUserPubkey = ref.read(currentPubkeySelectorProvider);

    return authorPubkey == currentUserPubkey;
  }

  IonConnectEntity? _getRelatedEntity(WidgetRef ref, {required IonNotification notification}) {
    final eventReference = switch (notification) {
      CommentIonNotification() => notification.eventReference,
      LikesIonNotification() => notification.eventReference,
      MentionIonNotification() => notification.eventReference,
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

    if (notification is LikesIonNotification) {
      return entity;
    }

    if (notification is MentionIonNotification) {
      return entity;
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
