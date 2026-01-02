// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/mentions_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/ion_notification_repository.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mentions_repository.r.g.dart';

@Riverpod(keepAlive: true)
MentionsRepository mentionsRepository(Ref ref) => MentionsRepository(
      mentionsDao: ref.watch(mentionsDaoProvider),
    );

class MentionsRepository implements IonNotificationRepository<MentionIonNotification> {
  MentionsRepository({
    required MentionsDao mentionsDao,
  }) : _mentionsDao = mentionsDao;

  final MentionsDao _mentionsDao;

  @override
  Future<void> save(IonConnectEntity entity) {
    return _mentionsDao.insert(
      Mention(
        eventReference: entity.toEventReference(),
        createdAt: entity.createdAt,
      ),
    );
  }

  Future<List<MentionIonNotification>> getNotificationsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final mentions = await _mentionsDao.getMentionsAfter(after: after, limit: limit);
    return mentions.map((mention) {
      return MentionIonNotification(
        eventReference: mention.eventReference,
        timestamp: mention.createdAt.toDateTime,
      );
    }).toList();
  }
}
