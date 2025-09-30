// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/providers/event_backfill_service.r.dart';
import 'package:ion/app/features/ion_connect/providers/global_subscription_event_dispatcher_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/global_subscription_latest_event_timestamp_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_subscription_provider.r.dart';
import 'package:ion/app/features/user/model/badges/badge_award.f.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_subscription.r.g.dart';

enum EventSource {
  pFilter,
  qFilter,
  subscription,
}

class GlobalSubscription {
  GlobalSubscription({
    required this.currentUserMasterPubkey,
    required this.devicePubkey,
    required this.latestEventTimestampService,
    required this.ionConnectNotifier,
    required this.globalSubscriptionNotifier,
    required this.globalSubscriptionEventDispatcher,
    required this.eventBackfillService,
  });

  final String currentUserMasterPubkey;
  final String devicePubkey;
  final GlobalSubscriptionLatestEventTimestampService latestEventTimestampService;
  final IonConnectNotifier ionConnectNotifier;
  final GlobalSubscriptionNotifier globalSubscriptionNotifier;
  final GlobalSubscriptionEventDispatcher globalSubscriptionEventDispatcher;
  final EventBackfillService eventBackfillService;

  static const List<int> _genericEventKinds = [
    BadgeAwardEntity.kind,
    FollowListEntity.kind,
    ReactionEntity.kind,
    ModifiablePostEntity.kind,
    GenericRepostEntity.modifiablePostRepostKind,
    ArticleEntity.kind,
  ];
  // Used when we reinstall the app to refetch all encrypted events
  static int? _inMemoryEncryptedSince;
  static const List<int> _encryptedEventKinds = [IonConnectGiftWrapEntity.kind];

  void init() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final regularFilterTimestamps = latestEventTimestampService.getAllRegularFilterTimestamps();

    if (latestEventTimestampService.hasNoRegularTimestamps()) {
      // All filter timestamps are null, update them with now and start subscription
      latestEventTimestampService.updateAllRegularTimestamps(now);
      _startSubscription();
    } else {
      // All timestamps exist, proceed with reconnection
      _reConnectToGlobalSubscription(
        regularFilterTimestamps: regularFilterTimestamps,
        now: now,
      );
    }
  }

  void _startSubscription() {
    _subscribe(
      eventLimit: 1,
    );
  }

  Future<void> _reConnectToGlobalSubscription({
    required Map<RegularFilterType, int?> regularFilterTimestamps,
    required int now,
  }) async {
    // Run backfill for each filter in parallel with separate event handlers
    final backfillServices = <Future<(RegularFilterType, int)>>[];

    // P filter backfill
    final pFilterTimestamp = regularFilterTimestamps[RegularFilterType.pFilter] ?? now;
    backfillServices.add(
      eventBackfillService
          .startBackfill(
            latestEventTimestamp: pFilterTimestamp,
            filter: RequestFilter(
              kinds: _genericEventKinds,
              tags: {
                '#p': [
                  [currentUserMasterPubkey],
                ],
              },
            ),
            onEvent: (event) => _handleEvent(event, eventSource: EventSource.pFilter),
          )
          .then((result) => (RegularFilterType.pFilter, result)),
    );

    // Q filter backfill
    final qFilterTimestamp = regularFilterTimestamps[RegularFilterType.qFilter] ?? now;
    backfillServices.add(
      eventBackfillService
          .startBackfill(
            latestEventTimestamp: qFilterTimestamp,
            filter: RequestFilter(
              kinds: const [ModifiablePostEntity.kind],
              tags: {
                '#Q': [
                  [null, null, currentUserMasterPubkey],
                ],
              },
            ),
            onEvent: (event) => _handleEvent(event, eventSource: EventSource.qFilter),
          )
          .then((result) => (RegularFilterType.qFilter, result)),
    );

    // Wait for all backfill operations to complete
    final backfillResults = await Future.wait(backfillServices);

    // Update each filter's timestamp based on its backfill result
    for (final (filterType, timestamp) in backfillResults) {
      await latestEventTimestampService.updateRegularFilter(timestamp, filterType);
    }

    // If during restoring of encrypted events user closed the app or moved to
    // background, we should restart subscription and refetch all encrypted events
    final shouldRefetchAllEncrypted = _inMemoryEncryptedSince != null;

    // If we have encrypted timestamp in storage, we subtract 2 days to account
    // for any events that might been created since last fetch time minus two days
    final encryptedLatestTimestampFromStorage =
        latestEventTimestampService.getEncryptedTimestamp() != null
            ? latestEventTimestampService.getEncryptedTimestamp()! -
                const Duration(days: 2).inMicroseconds
            : null;

    unawaited(
      _subscribe(
        eventLimit: 100,
        encryptedSince: shouldRefetchAllEncrypted ? null : encryptedLatestTimestampFromStorage,
      ),
    );
  }

  Future<void> _subscribe({
    required int eventLimit,
    int? encryptedSince,
  }) async {
    try {
      // Get per-filter timestamps for precise filtering
      final pFilterTimestamp =
          latestEventTimestampService.getRegularFilter(RegularFilterType.pFilter);
      final qFilterTimestamp =
          latestEventTimestampService.getRegularFilter(RegularFilterType.qFilter);

      final requestMessage = RequestMessage(
        filters: [
          RequestFilter(
            kinds: _genericEventKinds,
            tags: {
              '#p': [
                [currentUserMasterPubkey],
              ],
            },
            limit: eventLimit,
            since: pFilterTimestamp,
          ),
          RequestFilter(
            kinds: const [ModifiablePostEntity.kind],
            tags: {
              '#Q': [
                [null, null, currentUserMasterPubkey],
              ],
            },
            limit: eventLimit,
            since: qFilterTimestamp,
          ),
          RequestFilter(
            kinds: _encryptedEventKinds,
            tags: {
              '#p': [
                [currentUserMasterPubkey, '', devicePubkey],
              ],
            },
            since: encryptedSince,
          ),
        ],
      );

      globalSubscriptionNotifier.subscribe(
        requestMessage,
        onEndOfStoredEvents: () {
          // If we had finished to fetch all encrypted events, we can update
          // the timestamp in storage to avoid refetching them on next app start
          // and start using storage timestamp instead of in-memory one
          if (_inMemoryEncryptedSince != null) {
            latestEventTimestampService
                .updateEncryptedTimestampInStorage(DateTime.now().microsecondsSinceEpoch);
            _inMemoryEncryptedSince = null;
          }
        },
        onEvent: (event) => _handleEvent(event, eventSource: EventSource.subscription),
      );
    } catch (e) {
      throw GlobalSubscriptionSubscribeException(e);
    }
  }

  Future<void> _handleEvent(
    EventMessage eventMessage, {
    required EventSource eventSource,
  }) async {
    try {
      final eventType = eventMessage.kind == IonConnectGiftWrapEntity.kind
          ? EventType.encrypted
          : EventType.regular;

      final eventTimestamp = eventMessage.createdAt.toMicroseconds;

      if (eventType == EventType.regular) {
        switch (eventSource) {
          case EventSource.pFilter:
            await latestEventTimestampService.updateRegularFilter(
              eventTimestamp,
              RegularFilterType.pFilter,
            );
          case EventSource.qFilter:
            await latestEventTimestampService.updateRegularFilter(
              eventTimestamp,
              RegularFilterType.qFilter,
            );
          case EventSource.subscription:
            await latestEventTimestampService.updateAllRegularTimestamps(eventTimestamp);
        }
      } else {
        // For encrypted events, we only update the in-memory timestamp until
        // we finish restoring all encrypted events, then we update the storage
        // timestamp to avoid refetching them on next app start
        final hasTimestampInStorage = latestEventTimestampService.getEncryptedTimestamp() != null;
        if (!hasTimestampInStorage) {
          _inMemoryEncryptedSince ??= eventTimestamp;
        } else {
          await latestEventTimestampService
              .updateEncryptedTimestampInStorage(DateTime.now().microsecondsSinceEpoch);
        }
      }

      globalSubscriptionEventDispatcher.dispatch(eventMessage);
    } catch (e) {
      throw GlobalSubscriptionEventMessageHandlingException(e);
    }
  }
}

@riverpod
class GlobalSubscriptionNotifier extends _$GlobalSubscriptionNotifier {
  StreamSubscription<EventMessage>? _subscription;

  @override
  void build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  void subscribe(
    RequestMessage requestMessage, {
    required void Function(EventMessage) onEvent,
    void Function()? onEndOfStoredEvents,
  }) {
    final stream = ref.watch(
      ionConnectEventsSubscriptionProvider(
        requestMessage,
        onEndOfStoredEvents: onEndOfStoredEvents,
      ),
    );
    _subscription = stream.listen(onEvent);
  }
}

@riverpod
GlobalSubscription? globalSubscription(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final appState = ref.watch(appLifecycleProvider);

  if (appState != AppLifecycleState.resumed) {
    return null;
  }

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  final devicePubkey = ref.watch(currentUserIonConnectEventSignerProvider).valueOrNull?.publicKey;
  final delegationComplete = ref.watch(delegationCompleteProvider).valueOrNull.falseOrValue;

  if (currentUserMasterPubkey == null || devicePubkey == null || !delegationComplete) {
    return null;
  }

  final latestEventTimestampService =
      ref.watch(globalSubscriptionLatestEventTimestampServiceProvider);
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final globalSubscriptionNotifier = ref.watch(globalSubscriptionNotifierProvider.notifier);
  final globalSubscriptionEventDispatcherNotifier =
      ref.watch(globalSubscriptionEventDispatcherNotifierProvider).valueOrNull;
  final eventBackfillService = ref.watch(eventBackfillServiceProvider);

  if (latestEventTimestampService == null || globalSubscriptionEventDispatcherNotifier == null) {
    return null;
  }

  return GlobalSubscription(
    currentUserMasterPubkey: currentUserMasterPubkey,
    devicePubkey: devicePubkey,
    latestEventTimestampService: latestEventTimestampService,
    ionConnectNotifier: ionConnectNotifier,
    globalSubscriptionNotifier: globalSubscriptionNotifier,
    globalSubscriptionEventDispatcher: globalSubscriptionEventDispatcherNotifier,
    eventBackfillService: eventBackfillService,
  );
}
