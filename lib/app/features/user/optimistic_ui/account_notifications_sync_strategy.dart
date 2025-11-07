// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/optimistic_ui/model/account_notifications_option.f.dart';

class AccountNotificationsSyncStrategy implements SyncStrategy<AccountNotificationsOption> {
  AccountNotificationsSyncStrategy({
    required this.syncNotificationSet,
  });

  // Syncs a single notification set to the backend.
  final Future<void> Function(
    AccountNotificationSetType notificationSetType,
    String targetUserPubkey, {
    required bool shouldIncludeUser,
  }) syncNotificationSet;

  @override
  Future<AccountNotificationsOption> send(
    AccountNotificationsOption previous,
    AccountNotificationsOption optimistic,
  ) async {
    // Update all 4 notification sets (posts, stories, articles, videos)
    const allSetTypes = AccountNotificationSetType.values;
    for (final notificationSetType in allSetTypes) {
      final shouldIncludeUserInSet = _isNotificationTypeSelected(optimistic, notificationSetType);

      await syncNotificationSet(
        notificationSetType,
        optimistic.userPubkey,
        shouldIncludeUser: shouldIncludeUserInSet,
      );
    }
    return optimistic;
  }

  // Checks if the notification type is selected in the optimistic state.
  bool _isNotificationTypeSelected(
    AccountNotificationsOption optimistic,
    AccountNotificationSetType notificationSetType,
  ) {
    final notificationType = switch (notificationSetType) {
      AccountNotificationSetType.posts => UserNotificationsType.posts,
      AccountNotificationSetType.stories => UserNotificationsType.stories,
      AccountNotificationSetType.articles => UserNotificationsType.articles,
      AccountNotificationSetType.videos => UserNotificationsType.videos,
    };

    return optimistic.selected.contains(notificationType);
  }
}
