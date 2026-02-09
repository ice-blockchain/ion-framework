// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/model/related_relay.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/push_notifications/data/models/push_subscription.f.dart';
import 'package:ion/app/features/push_notifications/providers/push_subscription_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_ion_subscription_provider.r.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_subscription_sync_provider.r.g.dart';

@Riverpod(keepAlive: true)
class PushSubscriptionSync extends _$PushSubscriptionSync {
  @override
  Future<void> build() async {
    final authState = await ref.watch(authProvider.future);

    if (!authState.isAuthenticated) {
      return;
    }

    final delegationComplete = await ref.watch(delegationCompleteProvider.future);

    if (!delegationComplete) {
      return;
    }

    final selectedCategoriesSubscription =
        await ref.watch(selectedPushCategoriesIonSubscriptionProvider.future);
    final publishedSubscription = await ref.read(currentUserPushSubscriptionProvider.future);

    if (selectedCategoriesSubscription != null &&
        selectedCategoriesSubscription != publishedSubscription?.data) {
      if (selectedCategoriesSubscription.filters.isNotEmpty) {
        await _updateOwnSubscription(selectedCategoriesSubscription);
        await _updateExternalSubscription(
          currentData: selectedCategoriesSubscription,
          publishedData: publishedSubscription?.data,
        );
      } else if (publishedSubscription != null) {
        await _deleteOwnSubscription(publishedSubscription);
      }
    }
  }

  Future<void> _updateOwnSubscription(PushSubscriptionOwnData subscriptionData) async {
    await ref.watch(ionConnectNotifierProvider.notifier).sendEntityData(
          subscriptionData,
          actionSource: ActionSourceRelayUrl(subscriptionData.relay.url),
        );
  }

  Future<void> _updateExternalSubscription({
    required PushSubscriptionData currentData,
    required PushSubscriptionData? publishedData,
  }) async {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    final currentUserRelays = await ref.watch(currentUserRelaysProvider.future);
    if (currentPubkey == null || currentUserRelays == null) return;

    final currentExternalFilters = _buildPubkeysToFilters(filters: currentData.filters)
      ..remove(currentPubkey);
    final publishedExternalFilters = _buildPubkeysToFilters(filters: publishedData?.filters ?? [])
      ..remove(currentPubkey);

    final filtersToUpdate = Map.fromEntries(
      currentExternalFilters.entries.where(
        (entry) => !(currentExternalFilters[entry.key] ?? [])
            .equalsDeepUnordered(publishedExternalFilters[entry.key] ?? []),
      ),
    );

    final filtersToDelete = Map.fromEntries(
      publishedExternalFilters.entries
          .where((entry) => !currentExternalFilters.containsKey(entry.key)),
    );

    final dataToSync = {
      for (final entry in filtersToUpdate.entries)
        entry.key: _buildPushSubscriptionExternalData(
          masterPubkey: entry.key,
          filters: entry.value,
          currentUserRelays: currentUserRelays,
        ),
      for (final entry in filtersToDelete.entries)
        entry.key: _buildDeletePushSubscriptionExternalData(
          masterPubkey: entry.key,
        ),
    };

    await _sendExternalUsersPushSubscriptionData(pubkeysToData: dataToSync);
  }

  Map<String, List<RequestFilter>> _buildPubkeysToFilters({required List<RequestFilter> filters}) {
    final pubkeyToFilters = <String, List<RequestFilter>>{};
    for (final filter in filters) {
      final pubkeys = <String>{
        ...?filter.authors,
        ...?filter.tags?['#p']?.whereType<String>(),
      };
      for (final pubkey in pubkeys) {
        pubkeyToFilters
            .putIfAbsent(pubkey, () => [])
            .add(_buildUserSpecificFilter(filter: filter, pubkey: pubkey));
      }
    }
    return pubkeyToFilters;
  }

  /// Removes all other users apart the provided one for the filter
  RequestFilter _buildUserSpecificFilter({required RequestFilter filter, required String pubkey}) {
    final RequestFilter(:authors, :tags) = filter;
    final pTags = tags?['#p']?.whereType<String>();
    return filter.copyWith(
      authors: () => authors != null && authors.contains(pubkey) ? [pubkey] : null,
      tags: () => tags != null && pTags != null && pTags.contains(pubkey)
          ? {
              ...tags,
              '#p': [pubkey],
            }
          : null,
    );
  }

  Future<void> _deleteOwnSubscription(PushSubscriptionEntity entity) async {
    await ref.watch(ionConnectNotifierProvider.notifier).sendEntityData(
          DeletionRequest(
            events: [
              EventToDelete(
                eventReference: ImmutableEventReference(
                  masterPubkey: entity.masterPubkey,
                  eventId: entity.id,
                  kind: PushSubscriptionEntity.kind,
                ),
              ),
            ],
          ),
          cache: false,
        );
    ref.read(ionConnectCacheProvider.notifier).remove(entity.cacheKey);
  }

  /// TODO[push]: add comments to all methods in this class
  Future<void> _sendExternalUsersPushSubscriptionData({
    required Map<String, EventSerializable> pubkeysToData,
  }) async {
    final optimalUserRelaysService = ref.read(optimalUserRelaysServiceProvider);
    final ionConnectNotifier = ref.read(ionConnectNotifierProvider.notifier);

    if (pubkeysToData.length > 1) {
      final optimalUserRelays = await optimalUserRelaysService.fetch(
        masterPubkeys: pubkeysToData.keys.toList(),
        strategy: OptimalRelaysStrategy.mostUsers,
      );

      await Future.wait([
        for (final MapEntry(key: relayUrl, value: masterPubkeys) in optimalUserRelays.entries)
          ionConnectNotifier.sendEntitiesData(
            masterPubkeys.map((masterPubkey) => pubkeysToData[masterPubkey]).nonNulls.toList(),
            actionSource: ActionSource.relayUrl(relayUrl),
            cache: false,
          ),
      ]);
    } else {
      final MapEntry(key: masterPubkey, value: entityData) = pubkeysToData.entries.first;
      await ionConnectNotifier.sendEntityData(
        entityData,
        actionSource: ActionSource.user(masterPubkey),
        cache: false,
      );
    }
  }

  EventSerializable _buildPushSubscriptionExternalData({
    required String masterPubkey,
    required List<RequestFilter> filters,
    required UserRelaysEntity currentUserRelays,
  }) {
    return PushSubscriptionExternalData(
      externalUserMasterPubkey: masterPubkey,
      filters: filters,
      relays: currentUserRelays.urls.map((url) => RelatedRelay(url: url)).toList(),
    );
  }

  EventSerializable _buildDeletePushSubscriptionExternalData({
    required String masterPubkey,
  }) {
    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: ReplaceableEventReference(
            masterPubkey: masterPubkey,
            kind: PushSubscriptionEntity.kind,
            dTag: masterPubkey,
          ),
        ),
      ],
    );
    return deletionRequest;
  }
}
