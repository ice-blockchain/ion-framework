// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/ion_connect/ion_connect_logger.dart';
import 'package:ion/app/services/logger/logger.dart';

/// A wrapper around IonConnectRelay that adds enhanced logging for all relay interactions
class RelayLoggingWrapper implements IonConnectRelay {
  RelayLoggingWrapper(this._relay) : _relayUrl = _relay.url {
    _relay.messages.listen(_handleIncomingMessage);
  }

  final IonConnectRelay _relay;
  final String _relayUrl;

  // Map subscription IDs to session IDs for concurrent subscriptions
  final Map<String, String> _subscriptionToSession = {};

  String? _currentSessionId;

  set sessionId(String sessionId) {
    _currentSessionId = sessionId;
  }

  void clearSessionId() {
    _currentSessionId = null;
  }

  @override
  NostrSubscription subscribe(RequestMessage requestMessage) {
    final subscription = _relay.subscribe(requestMessage);

    final sessionId = subscription.id;
    _subscriptionToSession[sessionId] = sessionId;

    IonConnectLogger.startSessionWithId(sessionId);

    IonConnectLogger.trackComponent(sessionId, NostrMessageType.req.name);
    IonConnectLogger.logNetworkCallWithSession(
      relayUrl: _relayUrl,
      messageType: NostrMessageType.req,
      message: jsonEncode(requestMessage.toJson()),
      sessionId: sessionId,
      isOutgoing: true,
    );

    return subscription;
  }

  void _handleIncomingMessage(RelayMessage message) {
    String? sessionId;

    // For EVENT messages, use the subscription ID from the message is not available, use the current session ID
    if (message is EventMessage) {
      sessionId = _subscriptionToSession[message.subscriptionId];
    } else if (message is EoseMessage) {
      sessionId = _subscriptionToSession[message.subscriptionId];
    } else if (message is ClosedMessage) {
      sessionId = _subscriptionToSession[message.subscriptionId];
    } else {
      sessionId = _currentSessionId;
    }

    if (message is EventMessage) {
      final eventId = message.subscriptionId ?? message.sig ?? message.id;

      final isSubscriptionFlow = _subscriptionToSession.containsKey(message.subscriptionId);

      if (isSubscriptionFlow) {
        final hasTrackedAnyEvent =
            IonConnectLogger.hasComponent(eventId, NostrMessageType.event.name);

        if (!hasTrackedAnyEvent) {
          IonConnectLogger.trackComponent(eventId, NostrMessageType.event.name);
        }
      } else {
        IonConnectLogger.trackComponent(eventId, NostrMessageType.event.name);
      }

      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.event,
        message: jsonEncode(message.toJson()),
        sessionId: eventId,
        eventId: message.id,
        isOutgoing: false,
      );
    } else if (message is OkMessage) {
      // For OK messages, use the event ID as the session ID for unique identification
      final okSessionId = message.eventId;

      if (okSessionId.isNotEmpty) {
        final isDuplicate =
            IonConnectLogger.isDuplicateOkResponse(sessionId ?? '', _relayUrl, message.eventId);

        if (!isDuplicate) {
          IonConnectLogger.trackComponent(okSessionId, NostrMessageType.ok.name);

          IonConnectLogger.logNetworkCallWithSession(
            relayUrl: _relayUrl,
            messageType: NostrMessageType.ok,
            message: jsonEncode(message.toJson()),
            sessionId: okSessionId,
            eventId: message.eventId,
            accepted: message.accepted,
            errorMessage: message.message,
            isOutgoing: false,
          );
        }

        // Check if we can end the session (all relays have responded)
        final canEndSession = IonConnectLogger.trackOkReceivedFromRelay(
          sessionId ?? '',
          _relayUrl,
          message.eventId,
        );

        if (canEndSession) {
          IonConnectLogger.endSession(sessionId ?? '');
          _subscriptionToSession.remove(sessionId);
          if (_currentSessionId == sessionId) {
            _currentSessionId = null;
          }
        }
      }
    } else if (message is NoticeMessage) {
      if (sessionId != null) {
        IonConnectLogger.logNetworkCallWithSession(
          relayUrl: _relayUrl,
          messageType: NostrMessageType.notice,
          message: jsonEncode(message.toJson()),
          sessionId: sessionId,
          isOutgoing: false,
        );
      }
    } else if (message is ClosedMessage) {
      if (sessionId != null) {
        IonConnectLogger.trackComponent(sessionId, NostrMessageType.closed.name);

        IonConnectLogger.logNetworkCallWithSession(
          relayUrl: _relayUrl,
          messageType: NostrMessageType.closed,
          message: jsonEncode(message.toJson()),
          sessionId: sessionId,
          isOutgoing: false,
        );

        IonConnectLogger.endSession(sessionId);
        _subscriptionToSession.remove(sessionId);
        if (_currentSessionId == sessionId) {
          _currentSessionId = null;
        }
      }
    } else if (message is EoseMessage) {
      if (sessionId != null) {
        IonConnectLogger.trackComponent(sessionId, NostrMessageType.eose.name);

        IonConnectLogger.logNetworkCallWithSession(
          relayUrl: _relayUrl,
          messageType: NostrMessageType.eose,
          message: jsonEncode(message.toJson()),
          sessionId: sessionId,
          isOutgoing: false,
        );

        IonConnectLogger.endSession(sessionId);
        _subscriptionToSession.remove(sessionId);
        if (_currentSessionId == sessionId) {
          _currentSessionId = null;
        }
      }
    }
  }

  @override
  String get url => _relayUrl;

  @override
  Future<void> sendEvents(List<EventMessage> events) async {
    // Use existing session ID if set, otherwise create one from first event
    if (_currentSessionId == null && events.isNotEmpty) {
      final firstEvent = events.first;
      _currentSessionId = firstEvent.subscriptionId ?? firstEvent.sig ?? firstEvent.id;
      IonConnectLogger.startSessionWithId(_currentSessionId!);
    }

    if (_currentSessionId != null) {
      for (final event in events) {
        IonConnectLogger.trackEventSentToRelay(_currentSessionId!, _relayUrl, event.id);
        Logger.log('[DEBUG] Tracking event ${event.id} sent to relay $_relayUrl');
      }
    }

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final eventId = event.subscriptionId ?? event.sig ?? event.id;

      IonConnectLogger.trackComponent(eventId, NostrMessageType.event.name);

      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.event,
        message: jsonEncode(event.toJson()),
        sessionId: eventId,
        eventId: event.id,
        isOutgoing: true,
      );
    }
    await _relay.sendEvents(events);
  }

  @override
  void sendMessage(RelayMessage message) {
    _currentSessionId ??= '';

    if (message is EventMessage) {
      final eventId = message.subscriptionId ?? message.sig ?? message.id;

      IonConnectLogger.trackComponent(_currentSessionId!, NostrMessageType.event.name);
      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.event,
        message: jsonEncode(message.toJson()),
        sessionId: eventId,
        eventId: message.id,
        isOutgoing: false,
      );
    } else if (message is RequestMessage) {
      IonConnectLogger.trackComponent(_currentSessionId!, NostrMessageType.req.name);
      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.req,
        message: jsonEncode(message.toJson()),
        sessionId: _currentSessionId!,
      );
    } else if (message is AuthMessage) {
      try {
        final sig = (jsonDecode(message.challenge) as Map<String, dynamic>)['sig'] as String?;
        if (sig != null) {
          IonConnectLogger.trackComponent(sig, NostrMessageType.auth.name);

          IonConnectLogger.logNetworkCallWithSession(
            relayUrl: _relayUrl,
            messageType: NostrMessageType.auth,
            message: jsonEncode(message.toJson()),
            sessionId: sig,
          );
          _relay.sendMessage(message);
        }
      } catch (e) {
        Logger.error('[DEBUG] Error decoding challenge: $e');
      }
    }
  }

  @override
  void unsubscribe(String subscriptionId, {bool sendCloseMessage = true}) {
    final sessionId = _subscriptionToSession[subscriptionId] ?? _currentSessionId;

    if (sessionId != null) {
      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.closed,
        message: 'Unsubscribing subscription: $subscriptionId',
        sessionId: sessionId,
        showPrefix: false,
        isOutgoing: true,
      );
    } else {
      IonConnectLogger.logNetworkCall(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.closed,
        message: 'Unsubscribing subscription: $subscriptionId',
        subscriptionId: subscriptionId,
        showPrefix: false,
        isOutgoing: true,
      );
    }

    _relay.unsubscribe(subscriptionId, sendCloseMessage: sendCloseMessage);

    if (sessionId != null) {
      _subscriptionToSession.remove(subscriptionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
      }
    }

    IonConnectLogger.clearSubscriptionId(_relayUrl);
  }

  @override
  Stream<RelayMessage> get messages => _relay.messages;

  @override
  Stream<RelayMessage> get outgoingMessages => _relay.outgoingMessages;

  @override
  Stream<int> get subscriptionsCountStream => _relay.subscriptionsCountStream;

  @override
  void close() => _relay.close();

  @override
  Future<void> sendEvent(EventMessage event) async {
    if (_currentSessionId == null) {
      _currentSessionId = event.subscriptionId ?? event.sig ?? event.id;
      IonConnectLogger.startSessionWithId(_currentSessionId!);
    }

    if (_currentSessionId != null) {
      IonConnectLogger.trackEventSentToRelay(_currentSessionId!, _relayUrl, event.id);
    }

    final eventId = event.subscriptionId ?? event.sig ?? event.id;

    IonConnectLogger.trackComponent(eventId, NostrMessageType.event.name);

    IonConnectLogger.logNetworkCallWithSession(
      relayUrl: _relayUrl,
      messageType: NostrMessageType.event,
      message: jsonEncode(event.toJson()),
      sessionId: eventId,
      eventId: event.id,
      isOutgoing: true,
    );

    await _relay.sendEvent(event);
  }

  @override
  Stream<String> get onClose => _relay.onClose;

  @override
  WebSocket get socket => _relay.socket;

  @override
  set messages(Stream<RelayMessage> messages) => _relay.messages = messages;

  @override
  set outgoingMessages(Stream<RelayMessage> outgoingMessages) =>
      _relay.outgoingMessages = outgoingMessages;
}
