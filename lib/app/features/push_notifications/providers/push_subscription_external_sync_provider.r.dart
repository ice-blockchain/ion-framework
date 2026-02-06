// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/push_notifications/data/models/push_notification_category.dart';
import 'package:ion/app/features/push_notifications/providers/account_notification_set_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/accounts_push_subscription_service_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_provider.m.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_subscription_external_sync_provider.r.g.dart';

const equality = DeepCollectionEquality.unordered();

/// A provider, responsible for synchronizing push notification subscriptions
/// for the followed users when the push categories that depend on the follow list change.
@Riverpod(keepAlive: true)
class PushSubscriptionExternalSync extends _$PushSubscriptionExternalSync {
  @override
  Future<void> build() async {
    ref
      ..listen(selectedPushCategoriesProvider, (prev, next) async {
        if (prev != null &&
            !equality.equals(
              _categoriesDependantOnFollowedUsers(prev),
              _categoriesDependantOnFollowedUsers(next),
            )) {
          final currentUserFollowList = await ref.read(currentUserFollowListProvider.future);
          if (currentUserFollowList == null) {
            return;
          }

          await _syncUsersPushSubscriptions(masterPubkeys: currentUserFollowList.masterPubkeys);
        }
      })
      ..listen(currentUserAccountNotificationSetsProvider, (prev, next) async {
        final prevSets = prev?.valueOrNull;
        final nextSets = next.valueOrNull;
        if (prevSets != null && !equality.equals(prevSets, nextSets)) {
          final prevSetsMap = {for (final prevSet in prevSets) prevSet.data.type: prevSet};
          final nextSetsMap = nextSets != null
              ? {for (final nextSet in nextSets) nextSet.data.type: nextSet}
              : <AccountNotificationSetType, AccountNotificationSetEntity>{};
          final allTypes = {
            ...prevSetsMap.keys,
            ...nextSetsMap.keys,
          };
          final diffMasterPubkeys = <String>{
            for (final type in allTypes)
              ...() {
                final prevPubkeys = prevSetsMap[type]?.data.userPubkeys.toSet() ?? {};
                final nextPubkeys = nextSetsMap[type]?.data.userPubkeys.toSet() ?? {};
                return {
                  ...prevPubkeys.difference(nextPubkeys),
                  ...nextPubkeys.difference(prevPubkeys),
                };
              }(),
          };
          await _syncUsersPushSubscriptions(masterPubkeys: diffMasterPubkeys.toList());
        }
      });
  }

  List<PushNotificationCategory> _categoriesDependantOnFollowedUsers(
    SelectedPushCategoriesState pushCategoriesState,
  ) {
    const categoriesDependantOnFollowedUsers = [
      PushNotificationCategory.contentToken,
      PushNotificationCategory.contentToken,
    ];
    return pushCategoriesState.categories
        .where((category) => categoriesDependantOnFollowedUsers.contains(category))
        .toList();
  }

  /// Syncs external push subscriptions for provided users.
  ///
  /// This involves determining optimal relays, building push subscriptions for each user
  /// and sending the updated push subscriptions to ion connect.
  Future<void> _syncUsersPushSubscriptions({
    required List<String> masterPubkeys,
  }) async {
    final accountsPushSubscriptionService =
        await ref.read(accountsPushSubscriptionServiceProvider.future);
    final optimalUserRelaysService = ref.read(optimalUserRelaysServiceProvider);
    final ionConnectNotifier = ref.read(ionConnectNotifierProvider.notifier);

    if (masterPubkeys.length > 1) {
      final followedUsersFiltersEntries = await Future.wait<MapEntry<String, EventSerializable?>>(
        masterPubkeys.map(
          (masterPubkey) async => MapEntry(
            masterPubkey,
            await accountsPushSubscriptionService.buildSubscriptionForFollowedUser(
              masterPubkey: masterPubkey,
            ),
          ),
        ),
      );

      final followedUsersFilters = Map.fromEntries(followedUsersFiltersEntries);

      final followedUsersRelays = await optimalUserRelaysService.fetch(
        masterPubkeys: masterPubkeys,
        strategy: OptimalRelaysStrategy.mostUsers,
      );

      await Future.wait([
        for (final MapEntry(key: relayUrl, value: masterPubkeys) in followedUsersRelays.entries)
          ionConnectNotifier.sendEntitiesData(
            masterPubkeys
                .map(
                  (masterPubkey) => followedUsersFilters[masterPubkey],
                )
                .nonNulls
                .toList(),
            actionSource: ActionSource.relayUrl(relayUrl),
            cache: false,
          ),
      ]);
    } else {
      final masterPubkey = masterPubkeys.first;
      final filtersToSend = await accountsPushSubscriptionService.buildSubscriptionForFollowedUser(
        masterPubkey: masterPubkey,
      );
      if (filtersToSend != null) {
        await ionConnectNotifier.sendEntityData(
          filtersToSend,
          actionSource: ActionSource.user(masterPubkey),
          cache: false,
        );
      }
    }
  }
}
