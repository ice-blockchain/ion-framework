// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/dvm_error_entity.f.dart';
import 'package:ion/app/features/ion_connect/providers/dvm_transport_service.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'count_provider.r.g.dart';

@riverpod
class Count extends _$Count {
  // TODO: Generics available in riverpod, but this requires using the 3.0 dev release,
  // so we need to wait for the stable release to use it.
  @override
  Future<dynamic> build({
    required String key,
    required EventCountResultType type,
    required EventCountRequestData requestData,
    required ActionSource actionSource,
    Duration? cacheExpirationDuration,
    bool cache = true,
    bool network = true,
  }) async {
    final cacheKey = EventCountResultEntity.cacheKeyBuilder(key: key, type: type);

    if (cache) {
      final countEntity = ref.watch(
        ionConnectCacheProvider.select(
          cacheSelector<EventCountResultEntity>(
            cacheKey,
            expirationDuration: cacheExpirationDuration,
          ),
        ),
      );

      if (countEntity != null) {
        return countEntity.data.content;
      }
    }

    if (network) {
      final countEntity = await ref.read(dvmTransportServiceProvider).fetchEntity(
            actionSource: actionSource,
            requestData: requestData,
            requestDataTransformer: (requestData, relayUrl) => requestData is EventCountRequestData
                ? requestData.copyWith(relays: [relayUrl])
                : requestData,
            successKinds: const [EventCountResultEntity.kind],
            successParser: (eventMessage) =>
                EventCountResultEntity.fromEventMessage(eventMessage, key: key),
            timeout: const Duration(seconds: 30),
          );

      if (countEntity is! EventCountResultEntity?) {
        throw countEntity is DvmErrorEntity
            ? countEntity.toException()
            : UnknownEventException(eventId: countEntity.id);
      }

      if (cache && countEntity != null) {
        await ref.read(ionConnectCacheProvider.notifier).cache(countEntity);
      }

      return countEntity?.data.content;
    }

    return null;
  }
}
