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
import 'package:ion/app/features/push_notifications/providers/firebase_messaging_token_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/push_subscription_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/selected_push_categories_ion_subscription_provider.r.dart';
import 'package:ion/app/features/push_notifications/providers/synced_fcm_token_provider.r.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/features/user/providers/user_events_metadata_provider.r.dart';
import 'package:ion/app/services/device_id/device_id.r.dart';
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

    // App is not ready
    if (currentSubscriptionData == null) {
      return;
    }

    final fcmToken = await ref.watch(firebaseMessagingTokenProvider.future);
    if (fcmToken == null) {
      return;
    }

    final shouldUpdate = await _shouldUpdateSubscription(
      currentData: currentSubscriptionData,
      publishedSubscription: publishedSubscription,
      fcmToken: fcmToken,
    );

    if (!shouldUpdate) {
      return;
    }

    await Future.wait([
      _updateOwnSubscription(
        currentData: currentSubscriptionData,
        publishedEntity: publishedSubscription,
      ),
      _updateExternalSubscription(
        currentData: currentSubscriptionData,
        publishedEntity: publishedSubscription,
      ),
    ]);

    await _saveSyncedFcmToken(fcmToken: fcmToken);
  }

  Future<bool> _shouldUpdateSubscription({
    required PushSubscriptionOwnData currentData,
    required PushSubscriptionEntity? publishedSubscription,
    required String fcmToken,
  }) async {
    // There is no published subscription yet, but there are selected categories
    if (publishedSubscription == null && currentData.filters.isNotEmpty) {
      return true;
    }

    // Just in case check
    final publishedData = publishedSubscription?.data;
    if (publishedData is! PushSubscriptionOwnData) {
      return false;
    }

    // Compare subscription filters
    if (!currentData.filters.equalsDeepUnordered(publishedData.filters)) {
      return true;
    }

    // Manually compare the synced fcm token with the current one,
    // because the public one is encrypted with a random nonce.
    // Meaning the same token will look different on the relay after each encryption,
    // so we can't rely on the equality of encrypted tokens.
    final syncedFcmToken = ref.watch(syncedFcmTokenProvider);
    return syncedFcmToken != fcmToken;
  }

  Future<void> _saveSyncedFcmToken({required String fcmToken}) async {
    await ref.read(syncedFcmTokenProvider.notifier).setToken(fcmToken);
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
    final deviceId = await ref.watch(deviceIdServiceProvider).get();
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
          deviceId: deviceId,
          filters: entry.value,
          currentUserRelays: currentUserRelays,
        ),
      for (final entry in filtersToDelete.entries)
        entry.key:
            _buildDeletePushSubscriptionExternalData(masterPubkey: entry.key, deviceId: deviceId),
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
    final userEventsMetadataBuilder = await ref.read(userEventsMetadataBuilderProvider.future);

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
            metadataBuilders: [userEventsMetadataBuilder],
            cache: false,
          ),
      ]);
    } else {
      final MapEntry(key: masterPubkey, value: entityData) = pubkeysToData.entries.first;
      await ionConnectNotifier.sendEntityData(
        entityData,
        actionSource: ActionSource.user(masterPubkey),
        metadataBuilders: [userEventsMetadataBuilder],
        cache: false,
      );
    }
  }

  EventSerializable _buildPushSubscriptionExternalData({
    required String masterPubkey,
    required String deviceId,
    required List<RequestFilter> filters,
    required UserRelaysEntity currentUserRelays,
  }) {
    return PushSubscriptionExternalData(
      dTag: PushSubscriptionExternalDataDTag(
        deviceId: deviceId,
        externalUserMasterPubkey: masterPubkey,
      ),
      filters: filters,
      relays: currentUserRelays.urls.map((url) => RelatedRelay(url: url)).toList(),
    );
  }

  EventSerializable _buildDeletePushSubscriptionExternalData({
    required String masterPubkey,
    required String deviceId,
  }) {
    final deletionRequest = DeletionRequest(
      events: [
        EventToDelete(
          eventReference: ReplaceableEventReference(
            masterPubkey: masterPubkey,
            kind: PushSubscriptionEntity.kind,
            dTag: PushSubscriptionExternalDataDTag(
              deviceId: deviceId,
              externalUserMasterPubkey: masterPubkey,
            ).toString(),
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
