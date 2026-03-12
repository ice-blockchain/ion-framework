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

  static const Duration _defaultTimeout = Duration(seconds: 10);

  final RelayPicker _relayPicker;
  final IonConnectNotifier _ionConnectNotifier;
  final EventParser _eventParser;

  Future<T?> fetchEntity<R extends EventSerializable, T extends DvmResponseEntity>({
    required R requestData,
    required ActionSource actionSource,
    required List<int> successKinds,
    R Function(R requestData, String relayUrl)? requestDataTransformer,
    T Function(EventMessage eventMessage)? successParser,
    Duration timeout = _defaultTimeout,
  }) async {
    final responseEntity = await fetchEntities<R, T>(
      requestsData: [requestData],
      actionSource: actionSource,
      successKinds: successKinds,
      requestDataTransformer: requestDataTransformer,
      successParser: successParser,
      timeout: timeout,
    ).first;

    return responseEntity;
  }

  Stream<T?> fetchEntities<R extends EventSerializable, T extends DvmResponseEntity>({
    required List<R> requestsData,
    required ActionSource actionSource,
    required List<int> successKinds,
    R Function(R requestData, String relayUrl)? requestDataTransformer,
    T Function(EventMessage eventMessage)? successParser,
    Duration timeout = _defaultTimeout,
  }) async* {
    if (requestsData.isEmpty) {
      return;
    }

    final relay = await _getRelay(actionSource: actionSource);
    final relayUrl = relay.url;

    final preparedRequestsData = requestDataTransformer != null
        ? requestsData.map((requestData) => requestDataTransformer(requestData, relayUrl)).toList()
        : requestsData;

    final requestEvents = await Future.wait(preparedRequestsData.map(_ionConnectNotifier.sign));
    final requestEventIds = requestEvents.map((requestEvent) => requestEvent.id).toSet();

    final subscriptionMessage = RequestMessage()
      ..addFilter(
        RequestFilter(
          kinds: [...successKinds, DvmErrorEntity.kind],
          tags: {'#e': requestEventIds.toList()},
        ),
      );

    final subscription = relay.subscribe(subscriptionMessage);

    try {
      final responseStream = subscription.messages
          .where((message) => message is EventMessage)
          .cast<EventMessage>()
          .map<DvmResponseEntity?>(
            (message) => _parseResponseEntity(
              message,
              successKinds: successKinds,
              successParser: successParser,
            ),
          )
          .where((entity) {
        final requestId = entity?.requestEventReference.eventId;
        return requestId != null && requestEventIds.contains(requestId);
      }).asBroadcastStream();

      final responseFutures = [
        for (final requestEvent in requestEvents)
          responseStream
              .firstWhere((entity) => entity?.requestEventReference.eventId == requestEvent.id)
              .timeout(
                timeout,
                onTimeout: () => null, // If the BE has no response, nothing is returned
              ),
      ];

      await _ionConnectNotifier.sendEvents(
        requestEvents,
        actionSource: ActionSourceRelayUrl(relayUrl, anonymous: actionSource.anonymous),
        cache: false,
      );

      for (final responseFuture in responseFutures) {
        final responseEntity = await responseFuture;
        yield responseEntity as T?;
      }
    } finally {
      relay.unsubscribe(subscription.id);
    }
  }

  Future<IonConnectRelay> _getRelay({required ActionSource actionSource}) async {
    final relayEntries =
        await _relayPicker.getActionSourceRelays(actionSource, actionType: ActionType.read);
    return relayEntries.keys.first;
  }

  DvmResponseEntity? _parseResponseEntity<T extends DvmResponseEntity>(
    EventMessage message, {
    required List<int> successKinds,
    T Function(EventMessage eventMessage)? successParser,
  }) {
    if (message.kind == DvmErrorEntity.kind) {
      final responseEntity = DvmErrorEntity.fromEventMessage(message);
      throw DvmException(
        requestId: responseEntity.requestEventReference.eventId,
        status: responseEntity.data.status,
        details: responseEntity.data.content.toString(),
      );
    }

    if (!successKinds.contains(message.kind)) {
      throw IncorrectEventKindException(message, kind: message.kind);
    }

    if (successParser != null) {
      return successParser(message);
    }

    final parsedEntity = _eventParser.parse(message);
    if (parsedEntity is! DvmResponseEntity) {
      throw IncorrectEventKindException(message, kind: message.kind);
    }

    return parsedEntity;
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
