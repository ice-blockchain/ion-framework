// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
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
    const allSetTypes = AccountNotificationSetType.values;

    await Future.wait(
      allSetTypes.map((notificationSetType) async {
        final notificationType = notificationSetType.toUserNotificationType();
        final shouldIncludeUserInSet = optimistic.selected.contains(notificationType);

        await syncNotificationSet(
          notificationSetType,
          optimistic.userPubkey,
          shouldIncludeUser: shouldIncludeUserInSet,
        );
      }),
    );
    return optimistic;
  }
}
