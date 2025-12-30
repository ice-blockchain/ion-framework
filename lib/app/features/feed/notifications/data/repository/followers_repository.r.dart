// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/followers_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/ion_notification_repository.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'followers_repository.r.g.dart';

@Riverpod(keepAlive: true)
FollowersRepository followersRepository(Ref ref) => FollowersRepository(
      followersDao: ref.watch(followersDaoProvider),
    );

class FollowersRepository implements IonNotificationRepository {
  FollowersRepository({
    required FollowersDao followersDao,
  }) : _followersDao = followersDao;

  final FollowersDao _followersDao;

  @override
  Future<void> save(IonConnectEntity entity) {
    return _followersDao.insert(
      Follower(pubkey: entity.masterPubkey, createdAt: entity.createdAt),
    );
  }

  @override
  Future<List<FollowersIonNotification>> getNotifications() async {
    final aggregated = await _followersDao.getAggregated();
    return aggregated
        .map(
          (result) => FollowersIonNotification(
            total: result.uniquePubkeyCount,
            timestamp: result.lastCreatedAt?.toDateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
            pubkeys: result.latestPubkeys?.split(',') ?? [],
          ),
        )
        .toList();
  }

  Future<List<FollowersIonNotification>> getNotificationsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final aggregated = await _followersDao.getAggregatedAfter(after: after, limit: limit);
    return aggregated
        .map(
          (result) => FollowersIonNotification(
            total: result.uniquePubkeyCount,
            timestamp: result.lastCreatedAt?.toDateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
            pubkeys: result.latestPubkeys?.split(',') ?? [],
          ),
        )
        .toList();
  }
}
