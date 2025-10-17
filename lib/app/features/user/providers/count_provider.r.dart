// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_error_entity.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
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
  }) async {
    if (cache) {
      final countEntity = ref.watch(
        ionConnectCacheProvider.select(
          cacheSelector<EventCountResultEntity>(
            EventCountResultEntity.cacheKeyBuilder(
              key: key,
              type: type,
            ),
            expirationDuration: cacheExpirationDuration,
          ),
        ),
      );

      if (countEntity != null) {
        return countEntity.data.content as int;
      }
    }

    return _fetchCount(
      key: key,
      actionSource: actionSource,
      requestData: requestData,
    );
  }

  Future<dynamic> _fetchCount({
    required String key,
    required ActionSource actionSource,
    required EventCountRequestData requestData,
  }) async {
    final relay = await ref
        .read(relayPickerProvider.notifier)
        .getActionSourceRelays(actionSource, actionType: ActionType.read);

    final requestEvent =
        await _buildRequestEvent(relayUrl: relay.keys.first.url, requestData: requestData);

    final subscriptionMessage = RequestMessage()
      ..addFilter(
        RequestFilter(
          kinds: const [EventCountResultEntity.kind, EventCountErrorEntity.kind],
          tags: {
            '#e': [requestEvent.id],
          },
        ),
      );

    final subscription = relay.keys.first.subscribe(subscriptionMessage);

    try {
      final messagesFuture = subscription.messages
          .where((message) => message is EventMessage)
          .cast<EventMessage>()
          .map<dynamic>((message) {
            return switch (message.kind) {
              EventCountResultEntity.kind =>
                EventCountResultEntity.fromEventMessage(message, key: key),
              EventCountErrorEntity.kind => EventCountErrorEntity.fromEventMessage(message),
              _ => throw IncorrectEventKindException(message, kind: message.kind),
            };
          })
          .firstWhere(
            (entity) => switch (entity) {
              EventCountResultEntity() => entity.data.requestEventId == requestEvent.id,
              EventCountErrorEntity() => entity.data.eventReference.toString() == requestEvent.id,
              _ => false,
            },
          )
          .timeout(const Duration(seconds: 30));

      await ref.read(ionConnectNotifierProvider.notifier).sendEvent(
            requestEvent,
            actionSource: ActionSourceRelayUrl(relay.keys.first.url),
            cache: false,
          );

      final responseEntity = await messagesFuture;

      if (responseEntity is EventCountErrorEntity) {
        final errorContent = responseEntity.data.content;
        if (errorContent is String) {
          throw EventCountException(errorContent);
        } else {
          throw EventCountException('Unexpected error content type');
        }
      } else if (responseEntity is EventCountResultEntity) {
        await ref.read(ionConnectCacheProvider.notifier).cache(responseEntity);
        return responseEntity.data.content;
      }
    } finally {
      relay.keys.first.unsubscribe(subscription.id);
    }
  }

  Future<EventMessage> _buildRequestEvent({
    required String relayUrl,
    required EventCountRequestData requestData,
  }) async {
    final requestDataWithRelays = requestData.copyWith(
      relays: [relayUrl],
    );

    return ref.read(ionConnectNotifierProvider.notifier).sign(requestDataWithRelays);
  }
}
