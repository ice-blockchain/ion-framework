// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/likes_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/ion_notification_repository.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'likes_repository.r.g.dart';

@Riverpod(keepAlive: true)
LikesRepository likesRepository(Ref ref) => LikesRepository(
      likesDao: ref.watch(likesDaoProvider),
    );

class LikesRepository implements IonNotificationRepository {
  LikesRepository({
    required LikesDao likesDao,
  }) : _likesDao = likesDao;

  final LikesDao _likesDao;

  @override
  Future<void> save(IonConnectEntity entity) {
    if (entity is! ReactionEntity) {
      throw UnsupportedEventReference(entity.toEventReference());
    }
    final like = Like(
      eventReference: entity.data.eventReference,
      pubkey: entity.masterPubkey,
      createdAt: entity.createdAt,
    );
    return _likesDao.insert(like);
  }

  Future<List<LikesIonNotification>> getNotificationsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final aggregated = await _likesDao.getAggregatedAfter(after: after, limit: limit);

    return aggregated
        .map(
          (result) => LikesIonNotification(
            total: result.uniquePubkeyCount,
            eventReference: result.eventReference,
            timestamp: result.lastCreatedAt?.toDateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
            pubkeys: result.latestPubkeys?.split(',') ?? [],
          ),
        )
        .toList();
  }
}
