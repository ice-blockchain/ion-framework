// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/badge/providers/app_badge_counter_provider.r.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/unread_notifications_count_repository.r.dart';
import 'package:ion/app/services/local_notifications/local_notifications.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unread_notifications_count_provider.r.g.dart';

@riverpod
class UnreadNotificationsCount extends _$UnreadNotificationsCount {
  @override
  Stream<int> build() async* {
    final unreadCountRepository = ref.watch(unreadNotificationsCountRepositoryProvider);
    if (unreadCountRepository != null) {
      final appBadgeCounter = await ref.read(appBadgeCounterProvider.future);
      final unreadCountStream = unreadCountRepository.watch()
        ..listen(
          (count) => appBadgeCounter?.setBadgeCount(count, CounterCategory.inapp),
        );

      yield* unreadCountStream;
    }
  }

  Future<void> readAll() async {
    ref.read(unreadNotificationsCountRepositoryProvider)?.saveLastReadTime(DateTime.now());
    final appBadgeCounter = await ref.read(appBadgeCounterProvider.future);
    await appBadgeCounter?.clearBadge(CounterCategory.inapp);
    ref.invalidateSelf();
  }

  /// Cancels push notifications for the given list of notifications
  Future<void> cancelNotifications(List<IonNotification> notifications) async {
    try {
      final localNotificationsService = await ref.read(localNotificationsServiceProvider.future);

      // Get group keys (eventReference IDs) for all notifications
      final groupKeys = <String>[];
      for (final notification in notifications) {
        final eventReference = switch (notification) {
          final CommentIonNotification comment => comment.eventReference,
          final LikesIonNotification likesNotif => likesNotif.eventReference,
          final ContentIonNotification contentNotif => contentNotif.eventReference,
          final MentionIonNotification mention => mention.eventReference,
          _ => null,
        };

        if (eventReference != null) {
          groupKeys.add(eventReference.toString());
        }
      }

      if (groupKeys.isNotEmpty) {
        await localNotificationsService.cancelByGroupKeys(groupKeys);
      }
    } catch (e) {
      // Silently fail if we can't cancel notifications
    }
  }
}
