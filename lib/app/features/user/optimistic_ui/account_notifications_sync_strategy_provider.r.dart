// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/optimistic_ui/account_notifications_sync_strategy.dart';
import 'package:ion/app/features/user/optimistic_ui/model/account_notifications_option.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_notifications_sync_strategy_provider.r.g.dart';

@riverpod
class AccountNotificationsSyncStrategyNotifier extends _$AccountNotificationsSyncStrategyNotifier {
  @override
  SyncStrategy<AccountNotificationsOption> build() {
    return AccountNotificationsSyncStrategy(
      syncNotificationSet: (
        AccountNotificationSetType notificationSetType,
        String targetUserPubkey, {
        required bool shouldIncludeUser,
      }) async {
        final currentUsersSet = await _getCurrentUsersSet(notificationSetType);

        if (!_shouldUpdateSet(currentUsersSet, targetUserPubkey, shouldIncludeUser)) {
          return;
        }

        final updatedUsers =
            _buildUpdatedUsersSet(currentUsersSet, targetUserPubkey, shouldIncludeUser);

        await _sendIonConnectUpdate(notificationSetType, updatedUsers);
      },
    );
  }

  bool _shouldUpdateSet(
    Set<String> currentUsersSet,
    String targetUserPubkey,
    bool shouldIncludeUser,
  ) {
    if (shouldIncludeUser) {
      return !currentUsersSet.contains(targetUserPubkey);
    } else {
      return currentUsersSet.contains(targetUserPubkey);
    }
  }

  Set<String> _buildUpdatedUsersSet(
    Set<String> currentUsersSet,
    String targetUserPubkey,
    bool shouldIncludeUser,
  ) {
    final updatedUsers = {...currentUsersSet};
    if (shouldIncludeUser) {
      updatedUsers.add(targetUserPubkey);
    } else {
      updatedUsers.remove(targetUserPubkey);
    }
    return updatedUsers;
  }

  Future<Set<String>> _getCurrentUsersSet(
    AccountNotificationSetType notificationSetType,
  ) async {
    final currentMasterPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final entity = await ref.read(
      ionConnectEntityProvider(
        eventReference: ReplaceableEventReference(
          masterPubkey: currentMasterPubkey,
          kind: AccountNotificationSetEntity.kind,
          dTag: notificationSetType.dTagName,
        ),
      ).future,
    );
    if (entity is AccountNotificationSetEntity) {
      return entity.data.userPubkeys.toSet();
    }
    return <String>{};
  }

  Future<void> _sendIonConnectUpdate(
    AccountNotificationSetType notificationSetType,
    Set<String> updatedUsers,
  ) async {
    final setData = AccountNotificationSetData(
      type: notificationSetType,
      userPubkeys: updatedUsers.toList(),
    );

    await ref.read(ionConnectNotifierProvider.notifier).sendEntityData(setData);
  }
}
