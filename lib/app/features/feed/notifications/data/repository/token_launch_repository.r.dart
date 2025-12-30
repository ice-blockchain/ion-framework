// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/token_launch_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/ion_notification_repository.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_launch_repository.r.g.dart';

@Riverpod(keepAlive: true)
TokenLaunchRepository tokenLaunchRepository(Ref ref) => TokenLaunchRepository(
      tokenLaunchDao: ref.watch(tokenLaunchDaoProvider),
    );

class TokenLaunchRepository implements IonNotificationRepository<TokenLaunchIonNotification> {
  TokenLaunchRepository({
    required TokenLaunchDao tokenLaunchDao,
  }) : _tokenLaunchDao = tokenLaunchDao;

  final TokenLaunchDao _tokenLaunchDao;

  @override
  Future<void> save(IonConnectEntity entity) {
    if (entity is! CommunityTokenDefinitionEntity) {
      throw UnsupportedEventReference(entity.toEventReference());
    }
    final data = entity.data;
    if (data is! CommunityTokenDefinitionIon ||
        data.type != CommunityTokenDefinitionIonType.firstBuyAction) {
      throw UnsupportedEventReference(entity.toEventReference());
    }

    return _tokenLaunchDao.insert(
      TokenLaunch(
        eventReference: data.eventReference,
        createdAt: entity.createdAt,
      ),
    );
  }

  @override
  Future<List<TokenLaunchIonNotification>> getNotifications() async {
    final tokenLaunches = await _tokenLaunchDao.getAll();
    return tokenLaunches.map((tokenLaunch) {
      return TokenLaunchIonNotification(
        eventReference: tokenLaunch.eventReference,
        timestamp: tokenLaunch.createdAt.toDateTime,
      );
    }).toList();
  }

  Future<List<TokenLaunchIonNotification>> getNotificationsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final tokenLaunches = await _tokenLaunchDao.getTokenLaunchesAfter(after: after, limit: limit);
    return tokenLaunches.map((tokenLaunch) {
      return TokenLaunchIonNotification(
        eventReference: tokenLaunch.eventReference,
        timestamp: tokenLaunch.createdAt.toDateTime,
      );
    }).toList();
  }
}
