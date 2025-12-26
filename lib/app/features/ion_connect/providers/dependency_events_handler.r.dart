// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/ion_connect/providers/missing_events_handler.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dependency_events_handler.r.g.dart';

/// Handler for dependency ephemeral events.
///
/// Parses and caches wrapped events.
/// If parsing fails, that means that this is a missing event, and it will be handled later.
class DependencyEventsHandler implements EventsMetadataHandler {
  DependencyEventsHandler({
    required IonConnectCache ionConnectCache,
    required EventParser eventParser,
  })  : _ionConnectCache = ionConnectCache,
        _eventParser = eventParser;

  final IonConnectCache _ionConnectCache;
  final EventParser _eventParser;

  @override
  Future<Iterable<EventsMetadataEntity>> handle(Iterable<EventsMetadataEntity> events) async {
    if (events.isEmpty) {
      return events;
    }

    final missingEvents = <EventsMetadataEntity>[];
    for (final event in events) {
      try {
        final parsedEvent = _eventParser.parse(event.data.metadata);
        await _ionConnectCache.cache(parsedEvent);
      } catch (_) {
        // Parsing failed, meaning this is a missing event.
        // It will be handled later.
        missingEvents.add(event);
      }
    }

    return missingEvents;
  }
}

@riverpod
DependencyEventsHandler dependencyEventsHandler(Ref ref) {
  final ionConnectCache = ref.watch(ionConnectCacheProvider.notifier);
  final eventParser = ref.watch(eventParserProvider);
  return DependencyEventsHandler(ionConnectCache: ionConnectCache, eventParser: eventParser);
}
