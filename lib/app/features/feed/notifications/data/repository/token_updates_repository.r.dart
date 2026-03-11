// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/token_updates_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/ion_notification_repository.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_buying_activity_response.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_price_change_response.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/tokens_global_stat_response.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_updates_repository.r.g.dart';

@Riverpod(keepAlive: true)
TokenUpdatesRepository tokenUpdatesRepository(Ref ref) => TokenUpdatesRepository(
      tokenUpdatesDao: ref.watch(tokenUpdatesDaoProvider),
    );

class TokenUpdatesRepository implements IonNotificationRepository<TokenUpdateIonNotification> {
  TokenUpdatesRepository({
    required TokenUpdatesDao tokenUpdatesDao,
  }) : _tokenUpdatesDao = tokenUpdatesDao;

  final TokenUpdatesDao _tokenUpdatesDao;

  @override
  Future<void> save(IonConnectEntity entity) async {
    if (entity is! TokenPriceChangeResponseEntity &&
        entity is! TokenGlobalStatResponseEntity &&
        entity is! TokenBuyingActivityResponseEntity) {
      throw UnsupportedEventReference(entity.toEventReference());
    }

    if (entity is! EntityEventSerializable) {
      throw UnsupportedEntityType(entity);
    }

    final eventMessage = await (entity as EntityEventSerializable).toEntityEventMessage();

    await _tokenUpdatesDao.insert(
      TokenUpdate(
        id: entity.id,
        createdAt: entity.createdAt,
        kind: eventMessage.kind,
        eventMessage: entity,
      ),
    );
  }

  Future<List<TokenUpdateIonNotification>> getNotificationsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final tokenUpdates = await _tokenUpdatesDao.getTokenUpdatesAfter(after: after, limit: limit);
    return tokenUpdates
        .map(
          (tokenUpdate) => TokenUpdateIonNotification(
            entity: tokenUpdate.eventMessage,
            timestamp: tokenUpdate.createdAt.toDateTime,
          ),
        )
        .toList();
  }
}
