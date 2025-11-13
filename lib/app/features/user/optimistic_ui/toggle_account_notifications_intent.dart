// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/optimistic_ui/model/account_notifications_option.f.dart';

/// Intent to toggle a single notification type for a specific user.
/// Handles the `none` value and ensures empty sets normalize to `none`.
final class ToggleAccountNotificationsIntent
    implements OptimisticIntent<AccountNotificationsOption> {
  ToggleAccountNotificationsIntent(this.option);

  final UserNotificationsType option;

  @override
  AccountNotificationsOption optimistic(AccountNotificationsOption current) {
    final next = {...current.selected};

    if (option == UserNotificationsType.none) {
      return current.copyWith(selected: {UserNotificationsType.none});
    }

    next.remove(UserNotificationsType.none);

    if (!next.add(option)) {
      next.remove(option);

      // If set becomes empty after removal, default back to none.
      if (next.isEmpty) {
        next.add(UserNotificationsType.none);
      }
    }

    return current.copyWith(selected: next);
  }

  @override
  Future<AccountNotificationsOption> sync(
    AccountNotificationsOption prev,
    AccountNotificationsOption next,
  ) =>
      throw UnimplementedError('Sync is handled by strategy');
}
