// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
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
SyncStrategy<AccountNotificationsOption> accountNotificationsSyncStrategy(Ref ref) {
  final ionConnectNotifier = ref.read(ionConnectNotifierProvider.notifier);

  return AccountNotificationsSyncStrategy(
    syncNotificationSet: (
      AccountNotificationSetType notificationSetType,
      String targetUserPubkey, {
      required bool shouldIncludeUser,
    }) async {
      final currentMasterPubkey = ref.read(currentPubkeySelectorProvider);
      if (currentMasterPubkey == null) {
        return;
      }

      // Read current users in the set
      var currentUsers = <String>[];
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
        currentUsers = entity.data.userPubkeys;
      }

      // Compute updated user list based on whether user should be in the set
      final isUserAlreadyInSet = currentUsers.contains(targetUserPubkey);
      final updatedUsers = _buildUpdatedUserList(
        currentUsers: currentUsers,
        targetUserPubkey: targetUserPubkey,
        shouldIncludeUser: shouldIncludeUser,
        isUserAlreadyInSet: isUserAlreadyInSet,
      );

      // Skip write if no changes were made
      if (!_hasChanges(currentUsers, updatedUsers)) {
        return;
      }

      // Send updated set
      final setData = AccountNotificationSetData(
        type: notificationSetType,
        userPubkeys: updatedUsers,
      );

      await ionConnectNotifier.sendEntityData(setData);
    },
  );
}

// Builds the updated user list by adding or removing the target user.
List<String> _buildUpdatedUserList({
  required List<String> currentUsers,
  required String targetUserPubkey,
  required bool shouldIncludeUser,
  required bool isUserAlreadyInSet,
}) {
  if (shouldIncludeUser) {
    // Add user if not already in set
    return isUserAlreadyInSet ? currentUsers : [...currentUsers, targetUserPubkey];
  } else {
    // Remove user if present
    return isUserAlreadyInSet
        ? currentUsers.where((pubkey) => pubkey != targetUserPubkey).toList()
        : currentUsers;
  }
}

// Checks if two user lists have changes.
bool _hasChanges(List<String> currentUsers, List<String> updatedUsers) {
  if (identical(currentUsers, updatedUsers)) {
    return false;
  }

  // Compare lengths and elements
  if (updatedUsers.length != currentUsers.length) {
    return true;
  }

  return !_listEqualsInOrder(currentUsers, updatedUsers);
}

// Checks if both lists have the same items in the same order.
bool _listEqualsInOrder(List<String> a, List<String> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
