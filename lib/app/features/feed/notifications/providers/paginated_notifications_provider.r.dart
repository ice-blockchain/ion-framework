// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/notifications/data/database/tables/comments_table.d.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/model/notifications_tab_type.dart';
import 'package:ion/app/features/feed/notifications/data/model/paginated_notifications_state.f.dart';
import 'package:ion/app/features/feed/notifications/data/repository/comments_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/content_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/followers_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/likes_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/mentions_repository.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paginated_notifications_provider.r.g.dart';

@riverpod
class PaginatedNotifications extends _$PaginatedNotifications {
  static const int pageSize = 10;
  static const int visibleThreshold = 8;

  int _hiddenCount = 0;
  int _limit = pageSize;

  @override
  PaginatedNotificationsState build(NotificationsTabType type) {
    // Load initial notifications
    Future.microtask(_loadNotifications);
    return const PaginatedNotificationsState();
  }

  Future<void> _loadNotifications({DateTime? after}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      isInitialLoading: state.notifications.isEmpty,
    );

    try {
      final newNotifications = await _fetchNotifications(after: after);

      final allNotifications =
          after == null ? newNotifications : [...state.notifications, ...newNotifications];

      final lastTime = newNotifications.isNotEmpty
          ? newNotifications.last.timestamp
          : state.lastNotificationTime;

      state = state.copyWith(
        notifications: allNotifications,
        lastNotificationTime: lastTime,
        hasMore: newNotifications.length >= _limit,
        isLoading: false,
        isInitialLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialLoading: false,
      );
      rethrow;
    }
  }

  //counting hidden(notification for which the content was already removed) to avoid case when we have to few or any notifications on initial screen
  void registerHiddenNotification() {
    _hiddenCount++;
    _tryFetchMore();
  }

  //load more for case if there are a lot of hidden notifications for removed content on initial page
  void _tryFetchMore() {
    if (!state.hasMore || state.isLoading) {
      return;
    }
    final visibleCount = state.notifications.length - _hiddenCount;
    if (visibleCount < visibleThreshold && state.hasMore && !state.isLoading) {
      _limit += pageSize;
      loadMore();
    }
  }

  Future<List<IonNotification>> _fetchNotifications({DateTime? after}) async {
    return switch (type) {
      NotificationsTabType.all => _fetchAllNotifications(after: after),
      NotificationsTabType.comments => _fetchCommentsNotifications(after: after),
      NotificationsTabType.followers => _fetchFollowersNotifications(after: after),
      NotificationsTabType.likes => _fetchLikesNotifications(after: after),
    };
  }

  Future<List<IonNotification>> _fetchAllNotifications({
    DateTime? after,
  }) async {
    final commentsRepository = ref.watch(commentsRepositoryProvider);
    final contentRepository = ref.watch(contentRepositoryProvider);
    final followersRepository = ref.watch(followersRepositoryProvider);
    final likesRepository = ref.watch(likesRepositoryProvider);
    final mentionsRepository = ref.watch(mentionsRepositoryProvider);

    final (comments, content, likes, followers, mentions) = await (
      commentsRepository.getNotificationsAfter(after: after, limit: _limit),
      contentRepository.getNotificationsAfter(after: after, limit: _limit),
      likesRepository.getNotificationsAfter(after: after, limit: _limit),
      followersRepository.getNotificationsAfter(after: after, limit: _limit),
      mentionsRepository.getNotificationsAfter(after: after, limit: _limit),
    ).wait;

    final all = [...comments, ...content, ...likes, ...followers, ...mentions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return all.take(_limit).toList();
  }

  Future<List<IonNotification>> _fetchCommentsNotifications({
    DateTime? after,
  }) async {
    final commentsRepository = ref.watch(commentsRepositoryProvider);
    return commentsRepository.getNotificationsAfter(
      after: after,
      limit: _limit,
      type: CommentType.reply,
    );
  }

  Future<List<IonNotification>> _fetchFollowersNotifications({
    DateTime? after,
  }) async {
    final followersRepository = ref.watch(followersRepositoryProvider);
    return followersRepository.getNotificationsAfter(after: after, limit: _limit);
  }

  Future<List<IonNotification>> _fetchLikesNotifications({
    DateTime? after,
  }) async {
    final likesRepository = ref.watch(likesRepositoryProvider);
    return likesRepository.getNotificationsAfter(after: after, limit: _limit);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await _loadNotifications(after: state.lastNotificationTime);
  }

  Future<void> refresh() async {
    _hiddenCount = 0;
    _limit = pageSize;
    state = const PaginatedNotificationsState();
    await _loadNotifications();
  }
}
