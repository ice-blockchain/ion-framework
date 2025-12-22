// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';

/// Worker function to serialize a single entity in an isolate
@pragma('vm:entry-point')
Future<IonConnectCacheServiceEntity> serializeEntityFn(
  DbCacheableEntity entity,
) async {
  final cacheKey = entity.toEventReference().toString();
  final eventMessage = await entity.toEntityEventMessage();

  return (
    cacheKey: cacheKey,
    eventMessage: eventMessage,
  );
}

/// Worker function to serialize multiple entities in an isolate
@pragma('vm:entry-point')
Future<List<IonConnectCacheServiceEntity>> serializeEntitiesFn(
  List<DbCacheableEntity> entities,
) async {
  final results = <IonConnectCacheServiceEntity>[];

  for (final entity in entities) {
    final cacheKey = entity.toEventReference().toString();
    final eventMessage = await entity.toEntityEventMessage();

    results.add(
      (
        cacheKey: cacheKey,
        eventMessage: eventMessage,
      ),
    );
  }

  return results;
}
