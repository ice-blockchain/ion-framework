// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_backfill_service.r.g.dart';

class EventBackfillService {
  EventBackfillService({
    required this.ionConnectNotifier,
    required this.ref,
  });

  final IonConnectNotifier ionConnectNotifier;
  final Ref ref;

  Future<int> startBackfill({
    required int latestEventTimestamp,
    required RequestFilter filter,
    required void Function(EventMessage event) onEvent,
    ActionSource? actionSource,
  }) async {
    int? tmpLastCreatedAt;
    while (true) {
      final (maxCreatedAt, stopFetching) = await _fetchPagedEvents(
        initialLatestEventTimestamp: latestEventTimestamp,
        regularSince: tmpLastCreatedAt ?? latestEventTimestamp,
        filter: filter,
        onEvent: onEvent,
        actionSource: actionSource,
      );
      tmpLastCreatedAt = maxCreatedAt;
      if (stopFetching) {
        break;
      }
    }
    return tmpLastCreatedAt;
  }

  Future<(int maxCreatedAt, bool stopFetching)> _fetchPagedEvents({
    required int initialLatestEventTimestamp,
    required RequestFilter filter,
    required void Function(EventMessage event) onEvent,
    int? regularSince,
    int? regularUntil,
    int? previousMaxCreatedAt,
    Set<String> previousRegularIds = const {},
    int page = 1,
    ActionSource? actionSource,
  }) async {
    try {
      final appState = ref.read(appLifecycleProvider);
      if (appState != AppLifecycleState.resumed) {
        Logger.log(
          '[GLOBAL_SUBSCRIPTION] _backfill stopping backfill because app is backgrounded',
        );
        // return the initial latest event timestamp
        // to avoid setting invalid timestamp in storage
        return (initialLatestEventTimestamp, true);
      }
      final requestMessage = RequestMessage(
        filters: [
          filter.copyWith(
            since: () => regularSince?.toMicroseconds,
            until: () => regularUntil?.toMicroseconds,
            limit: () => 100,
          ),
        ],
      );

      var maxCreatedAt = previousMaxCreatedAt ?? initialLatestEventTimestamp;
      int? minCreatedAt;
      final regularIds = <String>{};
      await for (final event in ionConnectNotifier.requestEvents(
        requestMessage,
        actionSource: actionSource ?? const ActionSourceCurrentUser(),
      )) {
        final eventCreatedAt = event.createdAt.toMicroseconds;

        if (minCreatedAt == null || eventCreatedAt < minCreatedAt) {
          minCreatedAt = eventCreatedAt;
        }
        if (eventCreatedAt > maxCreatedAt) {
          maxCreatedAt = eventCreatedAt;
        }

        regularIds.add(event.id);
        if (!previousRegularIds.contains(event.id)) {
          onEvent(event);
        }
      }

      final nonDuplicateEventIds = regularIds.whereNot((id) => previousRegularIds.contains(id));

      if (nonDuplicateEventIds.isEmpty) {
        return (maxCreatedAt, page <= 2);
      }

      return _fetchPagedEvents(
        initialLatestEventTimestamp: initialLatestEventTimestamp,
        regularSince: regularSince,
        regularUntil: minCreatedAt,
        previousMaxCreatedAt: maxCreatedAt,
        previousRegularIds: {
          ...previousRegularIds,
          ...nonDuplicateEventIds,
        },
        page: page + 1,
        filter: filter,
        onEvent: onEvent,
        actionSource: actionSource,
      );
    } catch (e, st) {
      Logger.error(e, stackTrace: st);
      throw FetchMissingEventsException(e);
    }
  }
}

@riverpod
EventBackfillService eventBackfillService(Ref ref) {
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  return EventBackfillService(
    ionConnectNotifier: ionConnectNotifier,
    ref: ref,
  );
}
