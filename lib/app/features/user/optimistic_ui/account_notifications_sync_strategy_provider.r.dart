// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/push_notifications/providers/accounts_push_subscription_service_provider.r.dart';
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
        await Future.wait([
          _updateAccountNotificationSetData(
            externalUserMasterPubkey: targetUserPubkey,
            notificationSetType: notificationSetType,
            shouldIncludeUser: shouldIncludeUser,
          ),
          // Updating only external push subscription data as the current user's push subscription
          // will be synced via SelectedPushCategoriesIonSubscription
          _updateAccountPushSubscription(
            masterPubkey: targetUserPubkey,
            notificationSetType: notificationSetType,
            shouldIncludeUser: shouldIncludeUser,
          ),
        ]);
      },
    );
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

  Future<void> _updateAccountNotificationSetData({
    required String externalUserMasterPubkey,
    required AccountNotificationSetType notificationSetType,
    required bool shouldIncludeUser,
  }) async {
    final currentUsersSet = await _getCurrentUsersSet(notificationSetType);

    final shouldUpdateSet = shouldIncludeUser
        ? !currentUsersSet.contains(externalUserMasterPubkey)
        : currentUsersSet.contains(externalUserMasterPubkey);

    if (!shouldUpdateSet) {
      return;
    }

    final updatedUsers = shouldIncludeUser
        ? {...currentUsersSet, externalUserMasterPubkey}
        : currentUsersSet.where((userPubkey) => userPubkey != externalUserMasterPubkey);

    await _sendUpdatedAccountNotificationSetData(
      notificationSetType: notificationSetType,
      users: updatedUsers.toList(),
    );
  }

  Future<void> _updateAccountPushSubscription({
    required String masterPubkey,
    required AccountNotificationSetType notificationSetType,
    required bool shouldIncludeUser,
  }) async {
    final accountsPushSubscriptionService =
        await ref.read(accountsPushSubscriptionServiceProvider.future);
    final pushSubscription =
        await accountsPushSubscriptionService.buildSubscriptionOnAccountSettingsChange(
      masterPubkey: masterPubkey,
      notificationSetType: notificationSetType,
      shouldIncludeUser: shouldIncludeUser,
    );
    if (pushSubscription != null) {
      await ref.read(ionConnectNotifierProvider.notifier).sendEntityData(
            pushSubscription,
            actionSource: ActionSourceUser(masterPubkey),
            cache: false,
          );
    }
  }

  Future<void> _sendUpdatedAccountNotificationSetData({
    required AccountNotificationSetType notificationSetType,
    required List<String> users,
  }) async {
    final setData = AccountNotificationSetData(
      type: notificationSetType,
      userPubkeys: users,
    );

    await ref.read(ionConnectNotifierProvider.notifier).sendEntityData(setData);
  }
}
