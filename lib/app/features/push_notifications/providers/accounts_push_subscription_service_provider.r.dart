// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_relay.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription.f.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts_push_subscription_service_provider.r.g.dart';

class AccountsPushSubscriptionService {
  AccountsPushSubscriptionService({
    required UserRelaysEntity currentUserRelays,
    required IonConnectNotifier ionConnectNotifier,
    required Future<IonConnectEntity?> Function({required EventReference eventReference})
        getIonConnectEntity,
  })  : _currentUserRelays = currentUserRelays,
        _ionConnectNotifier = ionConnectNotifier,
        _getIonConnectEntity = getIonConnectEntity;

  final Future<IonConnectEntity?> Function({
    required EventReference eventReference,
  }) _getIonConnectEntity;

  final UserRelaysEntity _currentUserRelays;

  final IonConnectNotifier _ionConnectNotifier;

  /// Updates the external user push subscription when the current user
  /// changes their account notification settings for a specific user.
  Future<void> updateOnAccountSettingsChange({
    required String masterPubkey,
    required AccountNotificationSetType notificationSetType,
    required bool shouldIncludeUser,
  }) async {
    //TODO[push]: check posts category, if not enabled - return right away

    final currentFilters = await _getUserSubscriptionFilters(masterPubkey: masterPubkey);

    final notificationType = notificationSetType.toUserNotificationType();

    if (shouldIncludeUser) {
      final contains = currentFilters
          .any((filter) => UserNotificationsType.fromFilter(filter) == notificationType);
      if (contains) {
        return;
      }
      final updatedFilters = [
        ...currentFilters,
        notificationType.toRequestFilter(authors: [masterPubkey]),
      ];

      await _sendUpdatedPushSubscriptionExternalData(
        masterPubkey: masterPubkey,
        filters: updatedFilters,
      );
    } else {
      if (currentFilters.isEmpty) {
        return;
      }

      final updatedFilters = currentFilters.where((filter) {
        final type = UserNotificationsType.fromFilter(filter);
        return type != notificationType;
      }).toList();

      if (updatedFilters.length == currentFilters.length) {
        return;
      }

      if (updatedFilters.isEmpty) {
        await _deletePushSubscriptionExternalData(masterPubkey: masterPubkey);
      } else {
        await _sendUpdatedPushSubscriptionExternalData(
          masterPubkey: masterPubkey,
          filters: updatedFilters,
        );
      }
    }
  }

  Future<void> updateOnFollowToggle({
    required String masterPubkey,
    required bool following,
  }) async {
    //TODO[push]: check posts category, if not enabled - return right away

    final currentFilters = await _getUserSubscriptionFilters(masterPubkey: masterPubkey);

    // If we unfollow a user, we remove the push subscription entirely
    if (!following) {
      if (currentFilters.isNotEmpty) {
        await _deletePushSubscriptionExternalData(masterPubkey: masterPubkey);
      }
      return;
    } else {}
  }

  // call on
  // 1. change in push notification settings
  Future<void> updateFollowedUsersSubscriptions() async {
    // get current follow list

    // get current 30000 sets (check the pubkey in each set), build filters upon it
    // get current subscription categories (check if categories for follow list are on, check is posts is on)
    // compare with the current subscription, if not eq, send to relay
  }

  Future<List<RequestFilter>> _getUserSubscriptionFilters({
    required String masterPubkey,
  }) async {
    final pushSubscriptionReference = _buildPushSubscriptionEventReference(masterPubkey);

    final currentSubscriptionEntity =
        await _getIonConnectEntity(eventReference: pushSubscriptionReference);

    final currentFilters = switch (currentSubscriptionEntity) {
      PushSubscriptionEntity() => currentSubscriptionEntity.data.filters,
      _ => <RequestFilter>[],
    };

    return currentFilters;
  }

  Future<void> _sendUpdatedPushSubscriptionExternalData({
    required String masterPubkey,
    required List<RequestFilter> filters,
  }) async {
    final pushSubscription = PushSubscriptionExternalData(
      externalUserMasterPubkey: masterPubkey,
      filters: filters,
      relays: _currentUserRelays.urls.map((url) => RelatedRelay(url: url)).toList(),
    );

    await _ionConnectNotifier.sendEntityData(
      pushSubscription,
      actionSource: ActionSourceUser(masterPubkey),
      cache: false,
    );
  }

  Future<void> _deletePushSubscriptionExternalData({
    required String masterPubkey,
  }) async {
    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: _buildPushSubscriptionEventReference(masterPubkey),
        ),
      ],
    );
    await _ionConnectNotifier.sendEntityData(deletionRequest, cache: false);
  }

  EventReference _buildPushSubscriptionEventReference(String masterPubkey) {
    return ReplaceableEventReference(
      masterPubkey: masterPubkey,
      kind: PushSubscriptionEntity.kind,
      dTag: masterPubkey,
    );
  }
}

@Riverpod(keepAlive: true)
Future<AccountsPushSubscriptionService> accountsPushSubscriptionService(Ref ref) async {
  Future<IonConnectEntity?> getIonConnectEntity({required EventReference eventReference}) async =>
      ref.read(ionConnectEntityProvider(eventReference: eventReference).future);
  final currentUserRelays = await ref.watch(currentUserRelaysProvider.future);
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  if (currentUserRelays == null) {
    throw UserRelaysNotFoundException();
  }

  return AccountsPushSubscriptionService(
    currentUserRelays: currentUserRelays,
    ionConnectNotifier: ionConnectNotifier,
    getIonConnectEntity: getIonConnectEntity,
  );
}
