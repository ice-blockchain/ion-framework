// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/pubkey_tag.f.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/reaction_data.f.dart';
import 'package:ion/app/features/feed/data/models/q_tag.f.dart';
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
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_subscription.r.g.dart';

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
  static const List<int> _encryptedEventKinds = [IonConnectGiftWrapEntity.kind];

  int? _inMemoryEncryptedSince;

  void init() {
    Logger.log('[GLOBAL_SUBSCRIPTION] init');
    final now = DateTime.now().microsecondsSinceEpoch;
    final encryptedTimestamp = latestEventTimestampService.getEncryptedTimestamp();
    final pFilterTimestamp =
        latestEventTimestampService.getRegularFilter(RegularFilterType.pFilter);
    final qFilterTimestamp =
        latestEventTimestampService.getRegularFilter(RegularFilterType.qFilter);

    Logger.log(
      '[GLOBAL_SUBSCRIPTION] INITIALIZATION encrypted timestamp: $encryptedTimestamp formatted: ${encryptedTimestamp != null ? DateTime.fromMicrosecondsSinceEpoch(encryptedTimestamp).toIso8601String() : 'null'}, '
      'p filter timestamp: $pFilterTimestamp formatted: ${pFilterTimestamp != null ? DateTime.fromMicrosecondsSinceEpoch(pFilterTimestamp).toIso8601String() : 'null'}, '
      'q filter timestamp: $qFilterTimestamp formatted: ${qFilterTimestamp != null ? DateTime.fromMicrosecondsSinceEpoch(qFilterTimestamp).toIso8601String() : 'null'}, '
      'now: $now formatted: ${DateTime.fromMicrosecondsSinceEpoch(now).toIso8601String()}',
    );

    // if (pFilterTimestamp == null) {
    //   latestEventTimestampService.updateRegularFilter(now, RegularFilterType.pFilter);
    // }

    // if (qFilterTimestamp == null) {
    //   latestEventTimestampService.updateRegularFilter(now, RegularFilterType.qFilter);
    // }

    // if (encryptedTimestamp == null) {
    //   latestEventTimestampService.updateEncryptedTimestampInStorage();
    // }

    _subscribe(
      eventLimit: 100,
      pFilterTimestamp: pFilterTimestamp ?? now,
      qFilterTimestamp: qFilterTimestamp ?? now,
      encryptedSince: encryptedTimestamp,
    );

    _backFillEvents(
      pFilterTimestamp: pFilterTimestamp ?? now,
      qFilterTimestamp: qFilterTimestamp ?? now,
    );
  }

  Future<void> _backFillEvents({
    required int pFilterTimestamp,
    required int qFilterTimestamp,
  }) async {
    // Run backfill for each filter in parallel with separate event handlers

    final pFilterBackfillService = eventBackfillService
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
      onEvent: _handleEvent,
    )
        .then((latestEventMessageCreatedAt) {
      latestEventTimestampService.updateRegularFilter(
        latestEventMessageCreatedAt,
        RegularFilterType.pFilter,
      );
      return (RegularFilterType.pFilter, latestEventMessageCreatedAt);
    });

    final qFilterBackfillService = eventBackfillService
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
      onEvent: _handleEvent,
    )
        .then((latestEventMessageCreatedAt) {
      latestEventTimestampService.updateRegularFilter(
        latestEventMessageCreatedAt,
        RegularFilterType.qFilter,
      );
      return (RegularFilterType.qFilter, latestEventMessageCreatedAt);
    });

    final backfillServices = <Future<(RegularFilterType, int)>>[
      pFilterBackfillService,
      qFilterBackfillService,
    ];

    final backfillResults = await Future.wait(backfillServices);

    for (final result in backfillResults) {
      Logger.log(
        '[GLOBAL_SUBSCRIPTION] backfill result: ${result.$1} timestamp: ${result.$2} formatted: ${DateTime.fromMicrosecondsSinceEpoch(result.$2).toIso8601String()}',
      );
    }
  }

  Future<void> _subscribe({
    required int eventLimit,
    required int pFilterTimestamp,
    required int qFilterTimestamp,
    required int? encryptedSince,
  }) async {
    try {
      Logger.log(
        '[GLOBAL_SUBSCRIPTION] '
        'p filter subscription timestamp: $pFilterTimestamp formatted: ${DateTime.fromMicrosecondsSinceEpoch(pFilterTimestamp).toIso8601String()}, '
        'q filter subscription timestamp: $qFilterTimestamp formatted: ${DateTime.fromMicrosecondsSinceEpoch(qFilterTimestamp).toIso8601String()}, '
        'encrypted since: $encryptedSince formatted: ${encryptedSince != null ? DateTime.fromMicrosecondsSinceEpoch(encryptedSince).toIso8601String() : 'null'}',
      );
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
            since: encryptedSince != null
                ? encryptedSince - const Duration(days: 2).inMicroseconds
                : null,
          ),
        ],
      );

      globalSubscriptionNotifier.subscribe(
        requestMessage,
        onEndOfStoredEvents: () {
          Logger.log('[GLOBAL_SUBSCRIPTION] on EOSE');
          // If we had finished to fetch all encrypted events, we can update
          // the timestamp in storage to avoid refetching them on next app start
          // and start using storage timestamp instead of in-memory one
          if (_inMemoryEncryptedSince != null) {
            Logger.log('[GLOBAL_SUBSCRIPTION] updating encrypted timestamp in storage');
            latestEventTimestampService.updateEncryptedTimestampInStorage();
            _inMemoryEncryptedSince = null;
          }
        },
        onEvent: (event) {
          if (event.kind == IonConnectGiftWrapEntity.kind) {
            _inMemoryEncryptedSince ??= event.createdAt.toMicroseconds;
          } else {
            final tags = groupBy(event.tags, (tag) => tag[0]);

            final pubkeyTag = tags[PubkeyTag.tagName]?.firstOrNull;
            if (pubkeyTag != null) {
              final pTagValue = PubkeyTag.fromTag(pubkeyTag).value;
              if (pTagValue == currentUserMasterPubkey) {
                Logger.log(
                  '[GLOBAL_SUBSCRIPTION] updating p filter timestamp in storage timestamp: ${event.createdAt.toMicroseconds} formatted: ${DateTime.fromMicrosecondsSinceEpoch(event.createdAt.toMicroseconds).toIso8601String()}',
                );
                latestEventTimestampService.updateRegularFilter(
                  event.createdAt.toMicroseconds,
                  RegularFilterType.pFilter,
                );
              }
            }

            final qTag = tags[QTag.tagName]?.firstOrNull;
            if (qTag != null) {
              final qTagValue = QTag.fromTag(qTag).value;
              if (qTagValue == currentUserMasterPubkey) {
                Logger.log(
                  '[GLOBAL_SUBSCRIPTION] updating q filter timestamp in storage timestamp: ${event.createdAt.toMicroseconds} formatted: ${DateTime.fromMicrosecondsSinceEpoch(event.createdAt.toMicroseconds).toIso8601String()}',
                );
                latestEventTimestampService.updateRegularFilter(
                  event.createdAt.toMicroseconds,
                  RegularFilterType.qFilter,
                );
              }
            }
          }
          _handleEvent(event);
        },
      );
    } catch (e) {
      throw GlobalSubscriptionSubscribeException(e);
    }
  }

  Future<void> _handleEvent(EventMessage eventMessage) async {
    try {
      Logger.log(
        '[GLOBAL_SUBSCRIPTION] handling event: kind: ${eventMessage.kind}',
      );
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
