// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/badge/providers/app_badge_counter_provider.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/unread_notifications_count_repository.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unread_notifications_count_provider.r.g.dart';

@riverpod
class UnreadNotificationsCount extends _$UnreadNotificationsCount {
  @override
  Stream<int> build() async* {
    final unreadCountRepository = ref.watch(unreadNotificationsCountRepositoryProvider);
    if (unreadCountRepository != null) {
      final unreadCountStream = unreadCountRepository.watch()
        ..listen((count) async {
          final appBadgeCounter = await ref.read(appBadgeCounterProvider.future);
          await appBadgeCounter?.setBadgeCount(count);
        });
      yield* unreadCountStream;
    }
  }

  Future<void> readAll() async {
    ref.read(unreadNotificationsCountRepositoryProvider)?.saveLastReadTime(DateTime.now());
    final appBadgeCounter = await ref.read(appBadgeCounterProvider.future);
    await appBadgeCounter?.clearBadge();
    ref.invalidateSelf();
  }
}
