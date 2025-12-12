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
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/deletion_request.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';
import 'package:ion/app/features/ion_connect/providers/event_backfill_service.r.dart';
import 'package:ion/app/features/ion_connect/providers/events_management_service.r.dart';
import 'package:ion/app/features/ion_connect/providers/global_subscription_latest_event_timestamp_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_subscription_provider.r.dart';
import 'package:ion/app/features/user/model/badges/badge_award.f.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user_archive/model/entities/user_archive_entity.f.dart';
import 'package:ion/app/features/user_archive/providers/user_archive_provider.r.dart';
import 'package:ion/app/features/user_block/model/entities/blocked_user_entity.f.dart';
import 'package:ion/app/services/logger/logger.dart';
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
    required this.eventsManagementService,
    required this.eventBackfillService,
    required this.userArchiveService,
  });

  final String currentUserMasterPubkey;
  final String devicePubkey;
  final UserArchiveService? userArchiveService;
  final GlobalSubscriptionLatestEventTimestampService latestEventTimestampService;
  final IonConnectNotifier ionConnectNotifier;
  final GlobalSubscriptionNotifier globalSubscriptionNotifier;
  final EventsManagementService eventsManagementService;
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
  int? _inMemoryEncryptedSince;
  int? _inMemoryPFilterSince;
  int? _inMemoryQFilterSince;

  bool _isEoseProcessed = false;

  static const List<int> _encryptedEventKinds = [IonConnectGiftWrapEntity.kind];

  Future<void> init() async {
    Logger.log('[GLOBAL_SUBSCRIPTION] init');

    Logger.log('[GLOBAL_SUBSCRIPTION] init subscribing to encrypted delete events)');

    // As we get events from relays in reversed chronological order, we first
    // subscribe to encrypted delete events to ensure we process them before
    // any other encrypted events that might arrive later but were created earlier.
    // This prevents processing events that were deleted later on.
    await _subscribeToPriorityEvents();
    await userArchiveService?.checkArchiveMigrated();

    Logger.log('[GLOBAL_SUBSCRIPTION] init fetched encrypted delete events)');

    final now = DateTime.now().microsecondsSinceEpoch;

    if (latestEventTimestampService.hasNoRegularTimestamps()) {
      // All filter timestamps are null, update them with now and start subscription
      await latestEventTimestampService.updateAllRegularTimestamps(now);
      _startSubscription();
    } else {
      // All timestamps exist, proceed with reconnection
      await _reConnectToGlobalSubscription(now: now);
    }
  }

  void _startSubscription() {
    _subscribe(eventLimit: 1);
  }

  Future<void> _reConnectToGlobalSubscription({
    required int now,
  }) async {
    while (true) {
      Logger.log('[GLOBAL_SUBSCRIPTION] _backfill restart');
      final regularFilterTimestamps = latestEventTimestampService.getAllRegularFilterTimestamps();

      final pFilterTimestamp = regularFilterTimestamps[RegularFilterType.pFilter];
      final qFilterTimestamp = regularFilterTimestamps[RegularFilterType.qFilter];

      Logger.log('[GLOBAL_SUBSCRIPTION] _backfill restart pFilterTimestamp: $pFilterTimestamp');
      Logger.log('[GLOBAL_SUBSCRIPTION] _backfill restart qFilterTimestamp: $qFilterTimestamp');

      final latestTimestamps = await _backfill(
        pFilterTimestamp: pFilterTimestamp,
        qFilterTimestamp: qFilterTimestamp,
        now: now,
      );

      final fetchedPFilterTimestamp =
          latestTimestamps.firstWhere((result) => result.$1 == RegularFilterType.pFilter).$2;
      final fetchedQFilterTimestamp =
          latestTimestamps.firstWhere((result) => result.$1 == RegularFilterType.qFilter).$2;

      Logger.log(
        '[GLOBAL_SUBSCRIPTION] _backfill restart fetchedPFilterTimestamp: $fetchedPFilterTimestamp',
      );
      Logger.log(
        '[GLOBAL_SUBSCRIPTION] _backfill restart fetchedQFilterTimestamp: $fetchedQFilterTimestamp',
      );

      if (fetchedPFilterTimestamp == pFilterTimestamp &&
          fetchedQFilterTimestamp == qFilterTimestamp) {
        Logger.log('[GLOBAL_SUBSCRIPTION] _backfill restart break');
        break;
      }
    }

    // Wait for all backfill operations to complete

    // If we have an encrypted timestamp in storage, we subtract 2 days to account
    // for the potential random timestamp range of encrypted events. This ensures
    // that we refetch any encrypted events that might have been created with a
    // random timestamp up to 2 days before the last fetch time.
    final encryptedLatestTimestampFromStorage =
        latestEventTimestampService.getEncryptedTimestamp() != null
            ? latestEventTimestampService.getEncryptedTimestamp()! -
                const Duration(days: 2).inMicroseconds
            : null;

    unawaited(
      _subscribe(
        eventLimit: 100,
        encryptedSince: encryptedLatestTimestampFromStorage,
      ),
    );
  }

  Future<List<(RegularFilterType, int)>> _backfill({
    required int? pFilterTimestamp,
    required int? qFilterTimestamp,
    required int now,
  }) async {
    // Run backfill for each filter in parallel with separate event handlers
    final backfillServices = <Future<(RegularFilterType, int)>>[];

    Logger.log('[GLOBAL_SUBSCRIPTION] _backfill pFilterTimestamp: $pFilterTimestamp');

    // P filter backfill
    backfillServices.add(
      eventBackfillService
          .startBackfill(
        latestEventTimestamp: pFilterTimestamp ?? now,
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
          .then((result) {
        latestEventTimestampService.updateRegularFilter(result, RegularFilterType.pFilter);
        return (RegularFilterType.pFilter, result);
      }),
    );

    Logger.log('[GLOBAL_SUBSCRIPTION] _backfill qFilterTimestamp: $qFilterTimestamp');

    // Q filter backfill
    backfillServices.add(
      eventBackfillService
          .startBackfill(
        latestEventTimestamp: qFilterTimestamp ?? now,
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
          .then((result) {
        latestEventTimestampService.updateRegularFilter(result, RegularFilterType.qFilter);
        return (RegularFilterType.qFilter, result);
      }),
    );

    final result = await Future.wait(backfillServices);
    Logger.log('[GLOBAL_SUBSCRIPTION] _backfill result: $result');

    return result;
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

      Logger.log(
        '[GLOBAL_SUBSCRIPTION] _subscribe pFilterTimestamp: $pFilterTimestamp'
        ' formatted:  ${pFilterTimestamp != null ? DateTime.fromMicrosecondsSinceEpoch(pFilterTimestamp).toIso8601String() : 'null'}',
      );
      Logger.log(
        '[GLOBAL_SUBSCRIPTION] _subscribe qFilterTimestamp: $qFilterTimestamp'
        ' formatted:  ${qFilterTimestamp != null ? DateTime.fromMicrosecondsSinceEpoch(qFilterTimestamp).toIso8601String() : 'null'}',
      );
      Logger.log(
        '[GLOBAL_SUBSCRIPTION] _subscribe encryptedSince: $encryptedSince'
        ' formatted:  ${encryptedSince != null ? DateTime.fromMicrosecondsSinceEpoch(encryptedSince).toIso8601String() : 'null'}',
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
            since: encryptedSince,
          ),
        ],
      );

      globalSubscriptionNotifier.subscribe(
        requestMessage,
        onEndOfStoredEvents: () {
          _isEoseProcessed = true;

          // If we had finished to fetch all encrypted events, we can update
          // the timestamp in storage to avoid refetching them on next app start
          // and start using storage timestamp instead of in-memory one

          Logger.log('[GLOBAL_SUBSCRIPTION] EOSE');
          if (_inMemoryEncryptedSince != null) {
            Logger.log(
              '[GLOBAL_SUBSCRIPTION] EOSE updating encrypted timestamp in storage with in-memory timestamp: $_inMemoryEncryptedSince formatted: ${DateTime.fromMicrosecondsSinceEpoch(_inMemoryEncryptedSince!).toIso8601String()}',
            );
            latestEventTimestampService.updateEncryptedTimestampInStorage();
            _inMemoryEncryptedSince = null;
          }

          if (_inMemoryPFilterSince != null) {
            Logger.log(
              '[GLOBAL_SUBSCRIPTION] EOSE updating p filter timestamp in storage with in-memory timestamp: $_inMemoryPFilterSince formatted: ${DateTime.fromMicrosecondsSinceEpoch(_inMemoryPFilterSince!).toIso8601String()}',
            );
            latestEventTimestampService
                .updateRegularFilter(
              _inMemoryPFilterSince!,
              RegularFilterType.pFilter,
            )
                .then((_) {
              _inMemoryPFilterSince = null;
            });
          }
          if (_inMemoryQFilterSince != null) {
            Logger.log(
              '[GLOBAL_SUBSCRIPTION] EOSE updating q filter timestamp in storage with in-memory timestamp: $_inMemoryQFilterSince formatted: ${DateTime.fromMicrosecondsSinceEpoch(_inMemoryQFilterSince!).toIso8601String()}',
            );
            latestEventTimestampService
                .updateRegularFilter(
              _inMemoryQFilterSince!,
              RegularFilterType.qFilter,
            )
                .then((_) {
              _inMemoryQFilterSince = null;
            });
          }
        },
        onEvent: (event) => _handleEvent(event, eventSource: EventSource.subscription),
      );
    } catch (e) {
      throw GlobalSubscriptionSubscribeException(e);
    }
  }

  Future<void> _subscribeToPriorityEvents() async {
    final completer = Completer<void>();

    // If we have an encrypted timestamp in storage, we subtract 2 days to account
    // for the potential random timestamp range of encrypted events. This ensures
    // that we refetch any encrypted events that might have been created with a
    // random timestamp up to 2 days before the last fetch time.
    final encryptedLatestTimestampFromStorage =
        latestEventTimestampService.getEncryptedTimestamp() != null
            ? latestEventTimestampService.getEncryptedTimestamp()! -
                const Duration(days: 2).inMicroseconds
            : null;

    try {
      final requestMessage = RequestMessage(
        filters: [
          RequestFilter(
            kinds: _encryptedEventKinds,
            tags: {
              '#p': [
                [currentUserMasterPubkey, '', devicePubkey],
              ],
              '#k': [
                [DeletionRequestEntity.kind.toString()],
                [UserArchiveEntity.kind.toString()],
                [BlockedUserEntity.kind.toString()],
              ],
            },
            since: encryptedLatestTimestampFromStorage,
          ),
        ],
      );

      globalSubscriptionNotifier.subscribe(
        requestMessage,
        onEndOfStoredEvents: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onEvent: (event) => _handleEvent(event, eventSource: EventSource.subscription),
      );
      await completer.future;
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

      Logger.log('[GLOBAL_SUBSCRIPTION] _handleEvent eventMessage: $eventMessage');

      Logger.log('[GLOBAL_SUBSCRIPTION] _handleEvent regular event kind: ${eventMessage.kind}');

      if (eventType == EventType.regular) {
        final tags = groupBy(eventMessage.tags, (tag) => tag[0]);

        final pubkeyTag = tags[PubkeyTag.tagName]?.firstOrNull;
        if (pubkeyTag != null) {
          final pTagValue = PubkeyTag.fromTag(pubkeyTag).value;
          if (pTagValue == currentUserMasterPubkey) {
            if (_inMemoryPFilterSince == null) {
              _inMemoryPFilterSince = eventTimestamp;
            } else if (_inMemoryPFilterSince! < eventTimestamp) {
              _inMemoryPFilterSince = eventTimestamp;
            }
            if (_isEoseProcessed) {
              Logger.log(
                '[GLOBAL_SUBSCRIPTION] _handleEvent updating p filter timestamp in storage with in-memory timestamp: $_inMemoryPFilterSince formatted: ${DateTime.fromMicrosecondsSinceEpoch(_inMemoryPFilterSince!).toIso8601String()}',
              );
              await latestEventTimestampService.updateRegularFilter(
                _inMemoryPFilterSince!,
                RegularFilterType.pFilter,
              );
              _inMemoryPFilterSince = null;
            }
          }
        }

        final qTag = tags[QuotedReplaceableEvent.tagName]?.firstOrNull;
        if (qTag != null) {
          final qTagValue = QuotedReplaceableEvent.fromTag(qTag).eventReference.masterPubkey;
          if (qTagValue == currentUserMasterPubkey) {
            if (_inMemoryQFilterSince == null) {
              _inMemoryQFilterSince = eventTimestamp;
            } else if (_inMemoryQFilterSince! < eventTimestamp) {
              _inMemoryQFilterSince = eventTimestamp;
            }
            if (_isEoseProcessed) {
              Logger.log(
                '[GLOBAL_SUBSCRIPTION] _handleEvent updating q filter timestamp in storage with in-memory timestamp: $_inMemoryQFilterSince formatted: ${DateTime.fromMicrosecondsSinceEpoch(_inMemoryQFilterSince!).toIso8601String()}',
              );
              await latestEventTimestampService.updateRegularFilter(
                _inMemoryQFilterSince!,
                RegularFilterType.qFilter,
              );
              _inMemoryQFilterSince = null;
            }
          }
        }
      } else {
        _inMemoryEncryptedSince ??= eventTimestamp;
        if (_isEoseProcessed) {
          Logger.log(
            '[GLOBAL_SUBSCRIPTION] _handleEvent updating encrypted timestamp in storage with in-memory timestamp: $_inMemoryEncryptedSince formatted: ${DateTime.fromMicrosecondsSinceEpoch(_inMemoryEncryptedSince!).toIso8601String()}',
          );
          await latestEventTimestampService.updateEncryptedTimestampInStorage();
          _inMemoryEncryptedSince = null;
        }
      }

      eventsManagementService.dispatch(eventMessage);
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
    ref.listen(appLifecycleProvider, (previous, next) {
      if (next != AppLifecycleState.resumed) {
        Logger.log('[GLOBAL_SUBSCRIPTION] _subscription cancel on lifecycle change');
        _subscription?.cancel();
      }
    });
  }

  void subscribe(
    RequestMessage requestMessage, {
    required void Function(EventMessage) onEvent,
    void Function()? onEndOfStoredEvents,
  }) {
    /// We subtract 1 minute from the since timestamp to avoid missing events.
    /// Because event's createdAt is set on client side.
    final sinceOverlap = const Duration(minutes: 1).inMicroseconds;
    final modifiedRequestMessage = requestMessage
      ..filters.map((filter) {
        return filter.copyWith(
          since: () => filter.since != null ? filter.since! - sinceOverlap : null,
        );
      }).toList();
    final appState = ref.watch(appLifecycleProvider);
    if (appState != AppLifecycleState.resumed) {
      // Do not subscribe to the stream if the app is in the background.
      // Subscribing while backgrounded can cause crashes and high resource usage,
      // especially when processing encrypted events.
      return;
    }

    // Cancel existing subscription to prevent duplicates
    _subscription?.cancel();

    final stream = ref.watch(
      ionConnectEventsSubscriptionProvider(
        modifiedRequestMessage,
        onEndOfStoredEvents: onEndOfStoredEvents,
      ),
    );
    Logger.log('[GLOBAL_SUBSCRIPTION] _subscription subscribe');
    _subscription = stream.listen(onEvent);
  }
}

@riverpod
GlobalSubscription? globalSubscription(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final appState = ref.watch(appLifecycleProvider);

  final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
  final devicePubkey = ref.watch(currentUserIonConnectEventSignerProvider).valueOrNull?.publicKey;
  final delegationComplete = ref.watch(delegationCompleteProvider).valueOrNull.falseOrValue;

  if (currentUserMasterPubkey == null || devicePubkey == null || !delegationComplete) {
    return null;
  }

  if (appState != AppLifecycleState.resumed) {
    return null;
  }

  final latestEventTimestampService =
      ref.watch(globalSubscriptionLatestEventTimestampServiceProvider);
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final globalSubscriptionNotifier = ref.watch(globalSubscriptionNotifierProvider.notifier);
  final eventsManagementService = ref.watch(eventsManagementServiceProvider).valueOrNull;
  final eventBackfillService = ref.watch(eventBackfillServiceProvider);
  final userArchiveService = ref.watch(userArchiveServiceProvider).valueOrNull;

  if (latestEventTimestampService == null || eventsManagementService == null) {
    return null;
  }

  return GlobalSubscription(
    currentUserMasterPubkey: currentUserMasterPubkey,
    devicePubkey: devicePubkey,
    latestEventTimestampService: latestEventTimestampService,
    ionConnectNotifier: ionConnectNotifier,
    globalSubscriptionNotifier: globalSubscriptionNotifier,
    eventsManagementService: eventsManagementService,
    eventBackfillService: eventBackfillService,
    userArchiveService: userArchiveService,
  );
}
