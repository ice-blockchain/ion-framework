// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_buying_activity_response.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_price_change_response.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/tokens_global_stat_response.f.dart';

sealed class IonNotification {
  IonNotification({required this.timestamp, required this.pubkeys});

  final DateTime timestamp;

  final List<String> pubkeys;
}

enum CommentIonNotificationType { reply, quote, repost }

final class CommentIonNotification extends IonNotification {
  CommentIonNotification({
    required this.type,
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final CommentIonNotificationType type;

  final EventReference eventReference;
}

final class MentionIonNotification extends IonNotification {
  MentionIonNotification({
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final EventReference eventReference;
}

final class LikesIonNotification extends IonNotification {
  LikesIonNotification({
    required this.eventReference,
    required this.total,
    required super.timestamp,
    required super.pubkeys,
  });

  final EventReference eventReference;

  final int total;
}

final class FollowersIonNotification extends IonNotification {
  FollowersIonNotification({
    required this.total,
    required super.timestamp,
    required super.pubkeys,
  });

  final int total;
}

enum ContentIonNotificationType { posts, stories, articles, videos }

final class ContentIonNotification extends IonNotification {
  ContentIonNotification({
    required this.type,
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final ContentIonNotificationType type;

  final EventReference eventReference;
}

final class TokenLaunchIonNotification extends IonNotification {
  TokenLaunchIonNotification({
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final EventReference eventReference;
}

final class TokenTransactionIonNotification extends IonNotification {
  TokenTransactionIonNotification({
    required this.eventReference,
    required super.timestamp,
  }) : super(pubkeys: [eventReference.masterPubkey]);

  final EventReference eventReference;
}

final class TokenUpdateIonNotification extends IonNotification {
  TokenUpdateIonNotification({
    required this.entity,
    required super.timestamp,
  }) : super(
          pubkeys: switch (entity) {
            TokenPriceChangeResponseEntity() => [entity.data.tokenDefinitionReference.masterPubkey],
            TokenGlobalStatResponseEntity() => [entity.data.tokenDefinition.masterPubkey],
            TokenBuyingActivityResponseEntity() => [entity.data.tokenDefinition.masterPubkey],
            _ => [],
          },
        );

  final IonConnectEntity entity;
}
