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

/// Synchronizes the push subscription data on relays for both the current user
/// and external users mentioned in the filters.
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

    final currentSubscriptionData =
        await ref.watch(selectedPushCategoriesIonSubscriptionProvider.future);
    final publishedSubscription = await ref.read(currentUserPushSubscriptionProvider.future);

    if (currentSubscriptionData != null && currentSubscriptionData != publishedSubscription?.data) {
      await _updateOwnSubscription(
        currentData: currentSubscriptionData,
        publishedEntity: publishedSubscription,
      );
      await _updateExternalSubscription(
        currentData: currentSubscriptionData,
        publishedEntity: publishedSubscription,
      );
    }
  }

  /// Handles push subscription data for the current user.
  ///
  /// It contains all filters (for the current user and external ones) and is published to the current user relays.
  Future<void> _updateOwnSubscription({
    required PushSubscriptionOwnData currentData,
    required PushSubscriptionEntity? publishedEntity,
  }) async {
    final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
    final cacheNotifier = ref.watch(ionConnectCacheProvider.notifier);
    if (currentData.filters.isNotEmpty) {
      await ionConnectNotifier.sendEntityData(
        currentData,
        actionSource: ActionSourceRelayUrl(currentData.relay.url),
      );
    } else if (publishedEntity != null) {
      await ionConnectNotifier.sendEntityData(
        _buildDeletePushSubscriptionOwnData(publishedEntity),
        cache: false,
      );
      cacheNotifier.remove(publishedEntity.cacheKey);
    }
  }

  /// Handles push subscription data for external users.
  ///
  /// It contains only filters related to a specific external user and is published to that user's relays.
  /// The flow is as follows:
  ///  1) Find all pubkeys in the filters except the current user's pubkey
  ///  2) For each pubkey, build a separate entity containing only filters related to that pubkey
  ///  3) Compute the diff between the newly built data and the already published ones
  ///  4) Publish the data with differences to the relays of the corresponding users
  Future<void> _updateExternalSubscription({
    required PushSubscriptionOwnData currentData,
    required PushSubscriptionEntity? publishedEntity,
  }) async {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    final currentUserRelays = await ref.watch(currentUserRelaysProvider.future);
    if (currentPubkey == null || currentUserRelays == null) return;

    final currentExternalFilters = _buildPubkeysToFilters(filters: currentData.filters)
      ..remove(currentPubkey);
    final publishedExternalFilters =
        _buildPubkeysToFilters(filters: publishedEntity?.data.filters ?? [])..remove(currentPubkey);

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
        entry.key: _buildDeletePushSubscriptionExternalData(masterPubkey: entry.key),
    };

    await _sendExternalUsersPushSubscriptionData(pubkeysToData: dataToSync);
  }

  /// Search for pubkeys in filters and build a map where
  ///   key is user pubkey
  ///   value is a list of filters related to this user (filters that have this pubkey in authors or in #p tags)
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

  /// Removes all other users except the provided one for the filter
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

  /// Publish external users push subscription data to their relays
  Future<void> _sendExternalUsersPushSubscriptionData({
    required Map<String, EventSerializable> pubkeysToData,
  }) async {
    if (pubkeysToData.isEmpty) return;

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
            masterPubkey: masterPubkey, //TODO[push]: add device_id
            kind: PushSubscriptionEntity.kind,
            dTag: masterPubkey,
          ),
        ),
      ],
    );
    return deletionRequest;
  }

  EventSerializable _buildDeletePushSubscriptionOwnData(
    PushSubscriptionEntity publishedSubscriptionEntity,
  ) {
    return DeletionRequest(
      events: [
        EventToDelete(
          eventReference: ImmutableEventReference(
            masterPubkey: publishedSubscriptionEntity.masterPubkey,
            eventId: publishedSubscriptionEntity.id,
            kind: PushSubscriptionEntity.kind,
          ),
        ),
      ],
    );
  }
}
