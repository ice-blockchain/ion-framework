// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/comments_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/followers_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/likes_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/mentions_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/subscribed_users_content_dao.m.dart';
import 'package:ion/app/features/feed/notifications/data/database/dao/token_launch_dao.m.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';

part 'unread_notifications_count_repository.r.g.dart';

@Riverpod(keepAlive: true)
UnreadNotificationsCountRepository? unreadNotificationsCountRepository(Ref ref) {
  final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (identityKeyName == null) {
    return null;
  }
  return UnreadNotificationsCountRepository(
    userPreferencesService:
        ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName)),
    commentsDao: ref.watch(commentsDaoProvider),
    subscribedUsersContentDao: ref.watch(subscribedUsersContentDaoProvider),
    likesDao: ref.watch(likesDaoProvider),
    followersDao: ref.watch(followersDaoProvider),
    mentionsDao: ref.watch(mentionsDaoProvider),
    tokenLaunchDao: ref.watch(tokenLaunchDaoProvider),
  );
}

class UnreadNotificationsCountRepository {
  UnreadNotificationsCountRepository({
    required UserPreferencesService userPreferencesService,
    required CommentsDao commentsDao,
    required SubscribedUsersContentDao subscribedUsersContentDao,
    required LikesDao likesDao,
    required FollowersDao followersDao,
    required MentionsDao mentionsDao,
    required TokenLaunchDao tokenLaunchDao,
  })  : _userPreferencesService = userPreferencesService,
        _commentsDao = commentsDao,
        _subscribedUsersContentDao = subscribedUsersContentDao,
        _likesDao = likesDao,
        _followersDao = followersDao,
        _mentionsDao = mentionsDao,
        _tokenLaunchDao = tokenLaunchDao;

  final UserPreferencesService _userPreferencesService;
  final CommentsDao _commentsDao;
  final SubscribedUsersContentDao _subscribedUsersContentDao;
  final LikesDao _likesDao;
  final FollowersDao _followersDao;
  final MentionsDao _mentionsDao;
  final TokenLaunchDao _tokenLaunchDao;

  Stream<int> watch() {
    final lastReadTime = _getOrInitLastReadTime();
    final likesStream = _likesDao.watchUnreadCount(after: lastReadTime);
    final commentsStream = _commentsDao.watchUnreadCount(after: lastReadTime);
    final contentStream = _subscribedUsersContentDao.watchUnreadCount(after: lastReadTime);
    final followersStream = _followersDao.watchUnreadCount(after: lastReadTime);
    final mentionsStream = _mentionsDao.watchUnreadCount(after: lastReadTime);
    final tokenLaunchStream = _tokenLaunchDao.watchUnreadCount(after: lastReadTime);
    return commentsStream.combineLatestAll(
      [likesStream, contentStream, followersStream, mentionsStream, tokenLaunchStream],
    ).map((data) => data.sum);
  }

  void saveLastReadTime(DateTime time) {
    _userPreferencesService.setValue<int>(_storeKey, time.millisecondsSinceEpoch);
  }

  DateTime _getOrInitLastReadTime() {
    final readTimestamp = _userPreferencesService.getValue<int>(_storeKey);
    if (readTimestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(readTimestamp);
    } else {
      final now = DateTime.now();
      saveLastReadTime(now);
      return now;
    }
  }

  static const String _storeKey = 'unread_notifications_read_timestamp';
}
