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

  // Legacy session ID for backward compatibility (will be removed)
  String? _currentSessionId;

  set sessionId(String sessionId) {
    _currentSessionId = sessionId;
  }

  void clearSessionId() {
    _currentSessionId = null;
  }

  /// Wraps the subscribe method to add logging
  @override
  NostrSubscription subscribe(RequestMessage requestMessage) {
    final subscription = _relay.subscribe(requestMessage);

    // Use subscription ID as session ID - this should be persistent
    final sessionId = subscription.id;
    _subscriptionToSession[sessionId] = sessionId;

    // Start session with subscription ID
    IonConnectLogger.startSessionWithId(sessionId);

    // Log REQ immediately since this is a persistent subscription
    IonConnectLogger.trackComponent(sessionId, 'REQ');
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
    // Determine the correct session ID based on the message
    String? sessionId;

    if (message is EventMessage) {
      // For EVENT messages, use the subscription ID from the message
      sessionId = _subscriptionToSession[message.subscriptionId];
    } else if (message is EoseMessage) {
      // For EOSE messages, use the subscription ID from the message
      sessionId = _subscriptionToSession[message.subscriptionId];
    } else if (message is ClosedMessage) {
      // For CLOSED messages, use the subscription ID from the message
      sessionId = _subscriptionToSession[message.subscriptionId];
    } else if (message is OkMessage) {
      // For OK messages, we need to find the session by event ID
      // This is more complex - we'll use the current session ID for now
      sessionId = _currentSessionId;
    } else {
      // For other messages, use the current session ID
      sessionId = _currentSessionId;
    }

    if (message is EventMessage) {
      if (sessionId != null) {
        // For subscription flows, only track the first EVENT component (regardless of EVENT ID)
        final isSubscriptionFlow = _subscriptionToSession.containsKey(message.subscriptionId);

        if (isSubscriptionFlow) {
          // For subscription flows, only track the first EVENT component (regardless of EVENT ID)
          final hasTrackedAnyEvent = IonConnectLogger.hasComponent(sessionId, 'EVENT');

          // Debug logging
          Logger.log(
            '[DEBUG] Session $sessionId - EVENT ID: ${message.id}, Has tracked any EVENT: $hasTrackedAnyEvent',
          );

          if (!hasTrackedAnyEvent) {
            IonConnectLogger.trackComponent(sessionId, 'EVENT');
            Logger.log(
              '[DEBUG] Session $sessionId - Tracking first EVENT component for ID: ${message.id}',
            );
          } else {
            Logger.log(
              '[DEBUG] Session $sessionId - Skipping EVENT component for ID: ${message.id} (already tracked first EVENT)',
            );
          }
        } else {
          // For write flows, track every EVENT component
          IonConnectLogger.trackComponent(sessionId, 'EVENT');
        }

        IonConnectLogger.logNetworkCallWithSession(
          relayUrl: _relayUrl,
          messageType: NostrMessageType.event,
          message: jsonEncode(message.toJson()),
          sessionId: sessionId,
          eventId: message.id,
          isOutgoing: false, // We're receiving this event
        );
      }
    } else if (message is OkMessage) {
      if (sessionId != null) {
        // Check if this is a duplicate OK response before logging
        final isDuplicate =
            IonConnectLogger.isDuplicateOkResponse(sessionId, _relayUrl, message.eventId);

        if (!isDuplicate) {
          // Track OK component only for non-duplicates
          IonConnectLogger.trackComponent(sessionId, 'OK');

          IonConnectLogger.logNetworkCallWithSession(
            relayUrl: _relayUrl,
            messageType: NostrMessageType.ok,
            message: jsonEncode(message.toJson()),
            sessionId: sessionId,
            eventId: message.eventId,
            accepted: message.accepted,
            errorMessage: message.message,
            isOutgoing: false, // We're receiving this response
          );
        }

        // Check if we can end the session (all relays have responded)
        final canEndSession = IonConnectLogger.trackOkReceivedFromRelay(
          sessionId,
          _relayUrl,
          message.eventId,
        );

        if (canEndSession) {
          IonConnectLogger.endSession(sessionId);
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
        // Track CLOSED component
        IonConnectLogger.trackComponent(sessionId, 'CLOSED');

        IonConnectLogger.logNetworkCallWithSession(
          relayUrl: _relayUrl,
          messageType: NostrMessageType.closed,
          message: jsonEncode(message.toJson()),
          sessionId: sessionId,
          isOutgoing: false,
        );

        // Auto-end session on CLOSED
        IonConnectLogger.endSession(sessionId);
        _subscriptionToSession.remove(sessionId);
        if (_currentSessionId == sessionId) {
          _currentSessionId = null;
        }
      }
    } else if (message is EoseMessage) {
      if (sessionId != null) {
        // Track EOSE component
        IonConnectLogger.trackComponent(sessionId, 'EOSE');

        IonConnectLogger.logNetworkCallWithSession(
          relayUrl: _relayUrl,
          messageType: NostrMessageType.eose,
          message: jsonEncode(message.toJson()),
          sessionId: sessionId,
          isOutgoing: false,
        );

        // Auto-end session on EOSE
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

  /// Wraps the sendEvents method to add logging
  @override
  Future<void> sendEvents(List<EventMessage> events) async {
    // Use existing session ID if set, otherwise create one from first event
    if (_currentSessionId == null && events.isNotEmpty) {
      _currentSessionId = events.first.id; // Use first event ID as session ID
      IonConnectLogger.startSessionWithId(_currentSessionId!);
    }

    // Track that we're sending events to this relay
    if (_currentSessionId != null) {
      for (final event in events) {
        IonConnectLogger.trackEventSentToRelay(_currentSessionId!, _relayUrl, event.id);
        Logger.log('[DEBUG] Tracking event ${event.id} sent to relay $_relayUrl');
      }
    }

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      if (_currentSessionId != null) {
        IonConnectLogger.trackComponent(_currentSessionId!, 'EVENT');
      }
      final showPrefix = i == 0; // Only show prefix for the first event
      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.event,
        message: jsonEncode(event.toJson()),
        sessionId: _currentSessionId ?? '',
        eventId: event.id,
        showPrefix: showPrefix,
        isOutgoing: true, // We're sending this event
      );
    }
    await _relay.sendEvents(events);
  }

  /// Wraps the sendMessage method to add logging
  @override
  void sendMessage(RelayMessage message) {
    // Auto-create session if none exists
    _currentSessionId ??= '';

    if (message is EventMessage) {
      IonConnectLogger.trackComponent(_currentSessionId!, 'EVENT');
      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.event,
        message: jsonEncode(message.toJson()),
        sessionId: _currentSessionId!,
        eventId: message.id,
        isOutgoing: false, // We're receiving this event
      );
    } else if (message is RequestMessage) {
      IonConnectLogger.trackComponent(_currentSessionId!, 'REQ');
      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.req,
        message: jsonEncode(message.toJson()),
        sessionId: _currentSessionId!,
      );
    } else if (message is AuthMessage) {
      IonConnectLogger.trackComponent(_currentSessionId!, 'AUTH');
      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.auth,
        message: jsonEncode(message.toJson()),
        sessionId: _currentSessionId!,
      );
    }

    _relay.sendMessage(message);
  }

  /// Wraps the unsubscribe method
  @override
  void unsubscribe(String subscriptionId, {bool sendCloseMessage = true}) {
    // Get the session ID for this subscription
    final sessionId = _subscriptionToSession[subscriptionId] ?? _currentSessionId;

    if (sessionId != null) {
      IonConnectLogger.logNetworkCallWithSession(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.unsubscribe,
        message: 'Unsubscribing subscription: $subscriptionId',
        sessionId: sessionId,
        showPrefix: false,
        isOutgoing: true,
      );
    } else {
      IonConnectLogger.logNetworkCall(
        relayUrl: _relayUrl,
        messageType: NostrMessageType.unsubscribe,
        message: 'Unsubscribing subscription: $subscriptionId',
        subscriptionId: subscriptionId,
        showPrefix: false,
        isOutgoing: true,
      );
    }

    _relay.unsubscribe(subscriptionId, sendCloseMessage: sendCloseMessage);

    // Clear session if this was the subscription we were tracking
    if (sessionId != null) {
      _subscriptionToSession.remove(subscriptionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
      }
    }

    IonConnectLogger.clearSubscriptionId(_relayUrl);
  }

  /// Forwards other properties and methods to the wrapped relay
  @override
  Stream<RelayMessage> get messages => _relay.messages;

  @override
  Stream<RelayMessage> get outgoingMessages => _relay.outgoingMessages;

  @override
  Stream<int> get subscriptionsCountStream => _relay.subscriptionsCountStream;

  @override
  void close() => _relay.close();

  // Additional methods required by NostrRelay interface
  @override
  Future<void> sendEvent(EventMessage event) async {
    if (_currentSessionId == null) {
      _currentSessionId = event.id; // Use event ID as session ID
      IonConnectLogger.startSessionWithId(_currentSessionId!);
    }

    // Track that we're sending this event to this relay
    if (_currentSessionId != null) {
      IonConnectLogger.trackEventSentToRelay(_currentSessionId!, _relayUrl, event.id);
    }

    IonConnectLogger.trackComponent(_currentSessionId!, 'EVENT');
    IonConnectLogger.logNetworkCallWithSession(
      relayUrl: _relayUrl,
      messageType: NostrMessageType.event,
      message: jsonEncode(event.toJson()),
      sessionId: _currentSessionId!,
      eventId: event.id,
      isOutgoing: true, // We're sending this event
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
