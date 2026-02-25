// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/token_action_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/ion_notification_repository.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_action_repository.r.g.dart';

@Riverpod(keepAlive: true)
TokenActionRepository tokenActionRepository(Ref ref) => TokenActionRepository(
      tokenActionDao: ref.watch(tokenActionDaoProvider),
    );

class TokenActionRepository implements IonNotificationRepository<TokenTransactionIonNotification> {
  TokenActionRepository({
    required TokenActionDao tokenActionDao,
  }) : _tokenActionDao = tokenActionDao;

  final TokenActionDao _tokenActionDao;

  @override
  Future<void> save(IonConnectEntity entity) {
    if (entity is! CommunityTokenActionEntity) {
      throw UnsupportedEventReference(entity.toEventReference());
    }

    return _tokenActionDao.insert(
      TokenAction(
        eventReference: entity.toEventReference(),
        createdAt: entity.createdAt,
      ),
    );
  }

  Future<List<TokenTransactionIonNotification>> getNotificationsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final tokenActions = await _tokenActionDao.getTokenActionsAfter(after: after, limit: limit);
    return tokenActions.map((tokenAction) {
      return TokenTransactionIonNotification(
        eventReference: tokenAction.eventReference,
        timestamp: tokenAction.createdAt.toDateTime,
      );
    }).toList();
  }
}
