// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/subscribed_users_content_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/notifications_database.m.dart';
import 'package:ion/app/features/feed/notifications/data/model/content_type.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/ion_notification_repository.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_repository.r.g.dart';

@Riverpod(keepAlive: true)
ContentRepository contentRepository(Ref ref) => ContentRepository(
      subscribedUsersContentDao: ref.watch(subscribedUsersContentDaoProvider),
    );

class ContentRepository implements IonNotificationRepository {
  ContentRepository({
    required SubscribedUsersContentDao subscribedUsersContentDao,
  }) : _subscribedUsersContentDao = subscribedUsersContentDao;

  final SubscribedUsersContentDao _subscribedUsersContentDao;

  @override
  Future<void> save(IonConnectEntity entity) {
    final contentType = _getContentType(entity);
    if (contentType == null) throw UnsupportedEntityType(entity);

    return _subscribedUsersContentDao.insert(
      ContentNotification(
        eventReference: entity.toEventReference(),
        createdAt: entity.createdAt,
        type: contentType,
      ),
    );
  }

  @override
  Future<List<ContentIonNotification>> getNotifications() async {
    final contentNotifications = await _subscribedUsersContentDao.getAll();
    return contentNotifications.map((content) {
      final notificationType = switch (content.type) {
        ContentType.posts => ContentIonNotificationType.posts,
        ContentType.stories => ContentIonNotificationType.stories,
        ContentType.articles => ContentIonNotificationType.articles,
        ContentType.videos => ContentIonNotificationType.videos,
      };
      return ContentIonNotification(
        type: notificationType,
        eventReference: content.eventReference,
        timestamp: content.createdAt.toDateTime,
      );
    }).toList();
  }

  Future<List<ContentIonNotification>> getNotificationsAfter({
    required int limit,
    DateTime? after,
  }) async {
    final contentNotifications = await _subscribedUsersContentDao.getContentAfter(
      after: after,
      limit: limit,
    );
    return contentNotifications.map((content) {
      final notificationType = switch (content.type) {
        ContentType.posts => ContentIonNotificationType.posts,
        ContentType.stories => ContentIonNotificationType.stories,
        ContentType.articles => ContentIonNotificationType.articles,
        ContentType.videos => ContentIonNotificationType.videos,
      };
      return ContentIonNotification(
        type: notificationType,
        eventReference: content.eventReference,
        timestamp: content.createdAt.toDateTime,
      );
    }).toList();
  }

  ContentType? _getContentType(IonConnectEntity entity) {
    return switch (entity) {
      PostEntity() when entity.isStory => ContentType.stories,
      PostEntity() when entity.data.videos.isNotEmpty => ContentType.videos,
      PostEntity() => ContentType.posts,
      ModifiablePostEntity() when entity.isStory => ContentType.stories,
      ModifiablePostEntity() when entity.data.videos.isNotEmpty => ContentType.videos,
      ModifiablePostEntity() => ContentType.posts,
      ArticleEntity() => ContentType.articles,
      _ => null,
    };
  }

  Future<DateTime?> lastCreatedAt() async {
    return _subscribedUsersContentDao.getLastCreatedAt();
  }
}
