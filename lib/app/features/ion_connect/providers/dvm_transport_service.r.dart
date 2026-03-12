// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/dvm_error_entity.f.dart';
import 'package:ion/app/features/ion_connect/model/dvm_response_entity.dart';
import 'package:ion/app/features/ion_connect/model/event_serializable.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_parser.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dvm_transport_service.r.g.dart';

class DvmTransportService {
  DvmTransportService({
    required RelayPicker relayPicker,
    required IonConnectNotifier ionConnectNotifier,
    required EventParser eventParser,
  })  : _relayPicker = relayPicker,
        _ionConnectNotifier = ionConnectNotifier,
        _eventParser = eventParser;

  static const Duration defaultTimeout = Duration(seconds: 30);

  final RelayPicker _relayPicker;
  final IonConnectNotifier _ionConnectNotifier;
  final EventParser _eventParser;

  Future<T?> fetchEntity<R extends EventSerializable, T extends DvmResponseEntity>({
    required R requestData,
    required ActionSource actionSource,
    required List<int> successKinds,
    R Function(R requestData, String relayUrl)? requestDataTransformer,
    T Function(EventMessage eventMessage)? successParser,
    Duration timeout = defaultTimeout,
  }) async {
    final relayEntries =
        await _relayPicker.getActionSourceRelays(actionSource, actionType: ActionType.read);
    final relay = relayEntries.keys.first;
    final relayUrl = relay.url;

    final preparedRequestData = requestDataTransformer != null
        ? requestDataTransformer(requestData, relayUrl)
        : requestData;

    final requestEvent = await _ionConnectNotifier.sign(preparedRequestData);

    final subscriptionMessage = RequestMessage()
      ..addFilter(
        RequestFilter(
          kinds: [...successKinds, DvmErrorEntity.kind],
          tags: {
            '#e': [requestEvent.id],
          },
        ),
      );

    final subscription = relay.subscribe(subscriptionMessage);

    try {
      final responseFuture = subscription.messages
          .where((message) => message is EventMessage)
          .cast<EventMessage>()
          .map<DvmResponseEntity>((message) {
            if (message.kind == DvmErrorEntity.kind) {
              return DvmErrorEntity.fromEventMessage(message);
            }

            if (!successKinds.contains(message.kind)) {
              throw IncorrectEventKindException(message, kind: message.kind);
            }

            if (successParser != null) {
              return successParser(message);
            }

            final parsedEntity = _eventParser.parse(message);
            if (parsedEntity is! DvmResponseEntity) {
              throw IncorrectEventKindException(message.id, kind: message.kind);
            }

            return parsedEntity;
          })
          .firstWhere((entity) => entity.requestEventReference.eventId == requestEvent.id)
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'No response received for DVM request after ${timeout.inSeconds} seconds',
              );
            },
          );

      await _ionConnectNotifier.sendEvent(
        requestEvent,
        actionSource: ActionSourceRelayUrl(relayUrl, anonymous: actionSource.anonymous),
        cache: false,
      );

      final responseEntity = await responseFuture;

      if (responseEntity is DvmErrorEntity) {
        throw DvmException(
          requestId: responseEntity.requestEventReference.eventId,
          status: responseEntity.data.status,
          details: responseEntity.data.content.toString(),
        );
      }

      return responseEntity as T;
    } finally {
      relay.unsubscribe(subscription.id);
    }
  }
}

@riverpod
DvmTransportService dvmTransportService(Ref ref) {
  return DvmTransportService(
    relayPicker: ref.watch(relayPickerProvider.notifier),
    ionConnectNotifier: ref.watch(ionConnectNotifierProvider.notifier),
    eventParser: ref.watch(eventParserProvider),
  );
}
