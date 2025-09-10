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

  @override
  Future<List<MentionIonNotification>> getNotifications() async {
    final mentions = await _mentionsDao.getAll();
    return mentions.map((mention) {
      return MentionIonNotification(
        eventReference: mention.eventReference,
        timestamp: mention.createdAt.toDateTime,
      );
    }).toList();
  }

  Future<List<Mention>> getAll() async {
    return _mentionsDao.getAll();
  }

  Future<DateTime?> getLastCreatedAt() async {
    return _mentionsDao.getLastCreatedAt();
  }

  Future<DateTime?> getFirstCreatedAt({DateTime? after}) async {
    return _mentionsDao.getFirstCreatedAt(after: after);
  }

  Stream<int> watchUnreadCount({required DateTime? after}) {
    return _mentionsDao.watchUnreadCount(after: after);
  }
}
