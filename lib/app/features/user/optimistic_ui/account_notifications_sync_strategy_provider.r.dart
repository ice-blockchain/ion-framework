// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/related_relay.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_sync_strategy.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription.f.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/optimistic_ui/account_notifications_sync_strategy.dart';
import 'package:ion/app/features/user/optimistic_ui/model/account_notifications_option.f.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
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
          _updateExternalPushSubscriptionData(
            externalUserMasterPubkey: targetUserPubkey,
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

  Future<void> _updateExternalPushSubscriptionData({
    required String externalUserMasterPubkey,
    required AccountNotificationSetType notificationSetType,
    required bool shouldIncludeUser,
  }) async {
    final externalPushSubscriptionReference = ReplaceableEventReference(
      masterPubkey: externalUserMasterPubkey,
      kind: PushSubscriptionEntity.kind,
      dTag: externalUserMasterPubkey,
    );

    // The notification types the current user is subscribed to receive from the external user
    final currentExternalSubscriptionEntity = await ref
        .read(ionConnectEntityProvider(eventReference: externalPushSubscriptionReference).future);

    final currentExternalFilters = switch (currentExternalSubscriptionEntity) {
      PushSubscriptionEntity() => currentExternalSubscriptionEntity.data.filters,
      _ => <RequestFilter>[],
    };

    final notificationType = notificationSetType.toUserNotificationType();

    if (shouldIncludeUser) {
      final contains = currentExternalFilters
          .any((filter) => UserNotificationsType.fromFilter(filter) == notificationType);
      if (contains) {
        return;
      }
      final updatedFilters = [
        ...currentExternalFilters,
        notificationType.toRequestFilter(authors: [externalUserMasterPubkey]),
      ];

      await _sendUpdatedPushSubscriptionExternalData(
        externalUserMasterPubkey: externalUserMasterPubkey,
        filters: updatedFilters,
      );
    } else {
      if (currentExternalFilters.isEmpty) {
        return;
      }

      final updatedFilters = currentExternalFilters.where((filter) {
        final type = UserNotificationsType.fromFilter(filter);
        return type != notificationType;
      }).toList();

      if (updatedFilters.length == currentExternalFilters.length) {
        return;
      }

      if (updatedFilters.isEmpty) {
        await _deletePushSubscriptionExternalData(
          externalUserMasterPubkey: externalUserMasterPubkey,
        );
      } else {
        await _sendUpdatedPushSubscriptionExternalData(
          externalUserMasterPubkey: externalUserMasterPubkey,
          filters: updatedFilters,
        );
      }
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

  Future<void> _sendUpdatedPushSubscriptionExternalData({
    required String externalUserMasterPubkey,
    required List<RequestFilter> filters,
  }) async {
    final currentUserRelays = await ref.read(currentUserRelaysProvider.future);

    if (currentUserRelays == null) {
      throw UserRelaysNotFoundException();
    }

    final pushSubscription = PushSubscriptionExternalData(
      externalUserMasterPubkey: externalUserMasterPubkey,
      filters: filters,
      relays: currentUserRelays.urls.map((url) => RelatedRelay(url: url)).toList(),
    );

    await ref.read(ionConnectNotifierProvider.notifier).sendEntityData(
          pushSubscription,
          actionSource: ActionSourceUser(externalUserMasterPubkey),
          cache: false,
        );
  }

  Future<void> _deletePushSubscriptionExternalData({
    required String externalUserMasterPubkey,
  }) async {
    final currentMasterPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: ReplaceableEventReference(
            masterPubkey: currentMasterPubkey,
            dTag: externalUserMasterPubkey,
            kind: PushSubscriptionEntity.kind,
          ),
        ),
      ],
    );
    await ref
        .read(ionConnectNotifierProvider.notifier)
        .sendEntityData(deletionRequest, cache: false);
  }
}
