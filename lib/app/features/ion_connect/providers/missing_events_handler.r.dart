// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'missing_events_handler.r.g.dart';

abstract class EventsMetadataHandler {
  FutureOr<Iterable<EventsMetadataEntity>> handle(Iterable<EventsMetadataEntity> events);
}

/// Handler for missing ephemeral events.
///
/// Fetches and caches referenced events.
/// The purpose of missing ephemeral events is to indicate that
/// a relay does not possess the requested data and that the client
/// should re-request it from the appropriate relays.
class MissingEventsHandler implements EventsMetadataHandler {
  MissingEventsHandler({
    required IonConnectEntitiesManager ionConnectEntitiesManager,
    required Duration userMetadataExpirationDuration,
  })  : _ionConnectEntitiesManager = ionConnectEntitiesManager,
        _userMetadataExpirationDuration = userMetadataExpirationDuration;

  final IonConnectEntitiesManager _ionConnectEntitiesManager;
  final Duration _userMetadataExpirationDuration;

  @override
  Future<Iterable<EventsMetadataEntity>> handle(Iterable<EventsMetadataEntity> events) async {
    if (events.isEmpty) {
      return events;
    }

    final eventReferences =
        events.map((event) => event.data.metadataEventReference).nonNulls.toList();

    final (match: userMetadataEvents, rest: restEvents) = eventReferences.partition(
      (event) => event.kind == UserMetadataEntity.kind,
    );

    await Future.wait([
      if (userMetadataEvents.isNotEmpty)
        _ionConnectEntitiesManager.fetch(
          eventReferences: userMetadataEvents,
          cacheStrategy: DatabaseCacheStrategy.returnIfNotExpired,
          expirationDuration: _userMetadataExpirationDuration,
        ),
      if (restEvents.isNotEmpty) _ionConnectEntitiesManager.fetch(eventReferences: restEvents),
    ]);

    return [];
  }
}

@riverpod
MissingEventsHandler missingEventsHandler(Ref ref) {
  final ionConnectEntitiesManager = ref.watch(ionConnectEntitiesManagerProvider.notifier);
  final userMetadataExpirationDuration = ref.watch(userMetadataCacheDurationProvider);
  return MissingEventsHandler(
    ionConnectEntitiesManager: ionConnectEntitiesManager,
    userMetadataExpirationDuration: userMetadataExpirationDuration,
  );
}
