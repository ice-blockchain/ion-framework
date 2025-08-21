// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:nostr_dart/nostr_dart.dart';

/// Enum for all Nostr message types used in logging
enum NostrMessageType {
  req('REQ'),
  event('EVENT'),
  ok('OK'),
  notice('NOTICE'),
  closed('CLOSED'),
  eose('EOSE'),
  auth('AUTH');

  const NostrMessageType(this.value);
  final String value;

  @override
  String toString() => value;
}

/// Session-based tracing for relay interactions
///
/// Usage example:
/// ```dart
/// // Start a session for a user action
/// final sessionId = IonConnectLogger.startSession();
///
/// // Set session ID on relay wrapper
/// relayWrapper.setSessionId(sessionId);
///
/// // Perform relay operations (all logs will be grouped by session)
/// await relay.sendEvent(event);
///
/// // End session when action is complete
/// IonConnectLogger.endSession(sessionId);
/// relayWrapper.clearSessionId();

class IonConnectLogger implements NostrDartLogger {
  factory IonConnectLogger() {
    return _instance ??= IonConnectLogger._();
  }

  IonConnectLogger._();

  static IonConnectLogger? _instance;
  static const _prefix = '🦩 IonConnect:';

  final Map<String, Stopwatch> _requestTimers = {};
  final Map<String, String> _subscriptionIds = {};
  final Map<String, String> _eventIds = {}; // Track event IDs for EVENT messages
  final Map<String, RequestMessage> _pendingRequests = {}; // Track pending REQ messages
  final Set<String> _loggedEventIds = {}; // Track logged EVENTs globally
  final Set<String> _loggedGroups = {}; // Track which groups have already shown prefix

  // Session management
  final Map<String, DateTime> _sessions = {};
  final Map<String, Map<String, DateTime>> _componentTimings = {};
  final Map<String, int> _accumulatedComponentTimes = {}; // Track sum of all component times
  final Map<String, Set<String>> _trackedEventIds = {}; // Track which EVENT IDs have been processed

  // Track which relays we're waiting for OK responses from
  final Map<String, Set<String>> _pendingRelays = {};
  final Map<String, Set<String>> _sentToRelays = {};

  // Track which events we sent to which relays
  final Map<String, Map<String, Set<String>>> _eventsPerRelay = {};

  // Track which OK responses we've already received to avoid duplicates
  final Map<String, Set<String>> _receivedOkResponses = {};

  @override
  bool get incomingMessageLoggingEnabled => false;

  @override
  bool get outgoingMessageLoggingEnabled => false;

  // Start a session with existing ID (for subscription IDs)
  void startSessionWithId(String sessionId) {
    _sessions[sessionId] = DateTime.now();
    _componentTimings[sessionId] = {};
    _accumulatedComponentTimes[sessionId] = 0; // Initialize accumulated time
    _trackedEventIds[sessionId] = {}; // Initialize tracked event IDs
    _pendingRelays[sessionId] = {};
    _sentToRelays[sessionId] = {};
    _eventsPerRelay[sessionId] = {};
    _receivedOkResponses[sessionId] = {}; // Initialize for new session

    // Clear any existing request timers to prevent stale timing data
    _requestTimers.clear();
  }

  // End a session with timing
  void endSession(String sessionId) {
    final startTime = _sessions[sessionId];
    if (startTime != null) {
      final accumulatedTime = _accumulatedComponentTimes[sessionId] ?? 0;
      final sessionDuration = DateTime.now().difference(startTime).inMilliseconds;

      // Debug logging
      Logger.log(
        '[DEBUG] Session $sessionId - Accumulated time: ${accumulatedTime}ms, Session duration: ${sessionDuration}ms',
      );

      // Use accumulated component time if available, otherwise use session duration
      final finalTime = accumulatedTime > 0 ? accumulatedTime : sessionDuration;

      Logger.log(
        '[DEBUG] Session $sessionId completed in ${finalTime}ms',
      );

      _sessions.remove(sessionId);
      _componentTimings.remove(sessionId);
      _accumulatedComponentTimes.remove(sessionId);
      _trackedEventIds.remove(sessionId);
      _pendingRelays.remove(sessionId);
      _sentToRelays.remove(sessionId);
      _eventsPerRelay.remove(sessionId);
      _receivedOkResponses.remove(sessionId); // Clear received OK responses for the session
    }
  }

  // Track a component timing for a session and accumulate the time
  void trackComponent(String sessionId, String componentName) {
    final componentTimings = _componentTimings[sessionId];
    final accumulatedTimes = _accumulatedComponentTimes[sessionId];

    if (componentTimings != null && accumulatedTimes != null) {
      final now = DateTime.now();
      componentTimings[componentName] = now;

      // Calculate time from session start to this component
      final sessionStart = _sessions[sessionId];
      if (sessionStart != null) {
        final componentTime = now.difference(sessionStart).inMilliseconds;

        // Add this component time to the accumulated total (relative time)
        final newAccumulatedTime = accumulatedTimes + componentTime;
        _accumulatedComponentTimes[sessionId] = newAccumulatedTime;

        // Debug logging
        Logger.log(
          '[DEBUG] Session $sessionId - Component $componentName: ${componentTime}ms, Accumulated: ${newAccumulatedTime}ms',
        );
      }
    } else {
      Logger.log(
        '[DEBUG] Session $sessionId - Component tracking failed: componentTimings=${componentTimings != null}, accumulatedTimes=${accumulatedTimes != null}',
      );
    }
  }

  // Check if a component has been tracked for a session
  bool hasComponent(String sessionId, String componentName) {
    final componentTimings = _componentTimings[sessionId];
    return componentTimings?.containsKey(componentName) ?? false;
  }

  // Check if an EVENT ID has been tracked for a session
  bool hasTrackedEventId(String sessionId, String eventId) {
    final trackedEventIds = _trackedEventIds[sessionId];
    return trackedEventIds?.contains(eventId) ?? false;
  }

  // Mark an EVENT ID as tracked for a session
  void trackEventId(String sessionId, String eventId) {
    final trackedEventIds = _trackedEventIds[sessionId];
    if (trackedEventIds != null) {
      trackedEventIds.add(eventId);
    }
  }

  // Check if an OK response is a duplicate (before logging)
  bool isDuplicateOkResponse(String sessionId, String relayUrl, String eventId) {
    final receivedOkResponses = _receivedOkResponses[sessionId];
    if (receivedOkResponses != null) {
      final okResponseKey = '$relayUrl:$eventId';
      return receivedOkResponses.contains(okResponseKey);
    }
    return false;
  }

  // Track that we sent an event to a relay
  void trackEventSentToRelay(String sessionId, String relayUrl, String eventId) {
    final sentToRelays = _sentToRelays[sessionId];
    final pendingRelays = _pendingRelays[sessionId];
    final eventsPerRelay = _eventsPerRelay[sessionId];

    if (sentToRelays != null && pendingRelays != null && eventsPerRelay != null) {
      sentToRelays.add(relayUrl);
      pendingRelays.add(relayUrl);

      // Track which events we sent to this relay
      if (!eventsPerRelay.containsKey(relayUrl)) {
        eventsPerRelay[relayUrl] = {};
      }
      eventsPerRelay[relayUrl]!.add(eventId);
    }
  }

  // Track that we received an OK response from a relay for a specific event
  bool trackOkReceivedFromRelay(String sessionId, String relayUrl, String eventId) {
    final pendingRelays = _pendingRelays[sessionId];
    final eventsPerRelay = _eventsPerRelay[sessionId];
    final receivedOkResponses = _receivedOkResponses[sessionId];

    if (pendingRelays != null && eventsPerRelay != null && receivedOkResponses != null) {
      // Check if we've already received this OK response
      final okResponseKey = '$relayUrl:$eventId';
      if (receivedOkResponses.contains(okResponseKey)) {
        return false; // Already processed this OK response
      }

      final eventsForRelay = eventsPerRelay[relayUrl];
      if (eventsForRelay != null) {
        eventsForRelay.remove(eventId);

        // If we've received OK for all events sent to this relay, remove it from pending
        if (eventsForRelay.isEmpty) {
          pendingRelays.remove(relayUrl);

          // If no more pending relays, we can end the session
          if (pendingRelays.isEmpty) {
            return true; // Session can be ended
          }
        }
      }
      // Add the event ID to the received OK responses set
      receivedOkResponses.add(okResponseKey);
      return false; // Session should continue
    }
    return false; // Session should continue
  }

  // End session with error (logs whatever we can)
  void endSessionWithError(String sessionId, [Object? error, StackTrace? stackTrace]) {
    final startTime = _sessions[sessionId];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);

      Logger.log(
        'Session $sessionId FAILED after ${duration.inMilliseconds}ms',
      );

      if (error != null) {
        Logger.log('Session $sessionId error: $error');
        if (stackTrace != null) {
          Logger.log('Session $sessionId stack trace: $stackTrace');
        }
      }

      _sessions.remove(sessionId);
      _componentTimings.remove(sessionId);
      _pendingRelays.remove(sessionId);
      _sentToRelays.remove(sessionId);
      _eventsPerRelay.remove(sessionId);
      _receivedOkResponses.remove(sessionId); // Clear received OK responses for the session
    }
  }

  // Log network call with session ID
  void logNetworkCallWithSession({
    required String relayUrl,
    required NostrMessageType messageType,
    required String message,
    required String sessionId,
    String? eventId,
    bool? accepted,
    String? errorMessage,
    bool showPrefix = true,
    bool? isOutgoing,
  }) {
    // Deduplicate EVENT messages globally
    if (messageType == NostrMessageType.event && eventId != null) {
      if (_loggedEventIds.contains(eventId)) {
        return; // Skip if already logged
      }
      _loggedEventIds.add(eventId);
    }

    logNetworkCall(
      relayUrl: relayUrl,
      messageType: messageType,
      message: message,
      sessionId: sessionId,
      eventId: eventId,
      accepted: accepted,
      errorMessage: errorMessage,
      showPrefix: showPrefix,
      isOutgoing: isOutgoing,
    );
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.info('$_prefix $message');
    if (error != null) {
      Logger.error('$_prefix $error', stackTrace: stackTrace);
    }
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.warning('$_prefix $message');
    if (error != null) {
      Logger.error('$_prefix $error', stackTrace: stackTrace);
    }
  }

  /// Logs a network call to a relay with enhanced information
  void logNetworkCall({
    required String relayUrl,
    required NostrMessageType messageType,
    required String message,
    String? subscriptionId,
    String? sessionId,
    String? eventId,
    bool? accepted,
    String? errorMessage,
    bool showPrefix = true, // Control whether to show the 🚀 NETWORK_CALL prefix
    bool? isOutgoing,
  }) {
    // Use session-based timing if sessionId is provided, otherwise fall back to relay-based timing
    var requestTime = 0;
    if (sessionId != null && _sessions.containsKey(sessionId)) {
      final sessionStart = _sessions[sessionId]!;
      requestTime = DateTime.now().difference(sessionStart).inMilliseconds;
    } else {
      final stopwatch = _requestTimers[relayUrl];
      requestTime = stopwatch?.elapsedMilliseconds ?? 0;
    }

    // Determine direction and appropriate emoji/prefix
    String emoji;
    String prefix;
    String direction;

    if (messageType == NostrMessageType.req || messageType == NostrMessageType.auth) {
      // Outgoing messages (we send these)
      emoji = '📤';
      prefix = '$emoji OUTGOING';
      direction = 'to $relayUrl';
    } else if (messageType == NostrMessageType.event && (isOutgoing ?? false)) {
      // Outgoing EVENT (we're sending it)
      emoji = '📤';
      prefix = '$emoji OUTGOING';
      direction = 'to $relayUrl';
    } else {
      // Incoming messages (EVENT, OK, EOSE, NOTICE, CLOSED)
      emoji = '📥';
      prefix = '$emoji INCOMING';
      direction = 'from $relayUrl';
    }

    var logMessage = showPrefix ? '$prefix [$messageType] $direction' : '[$messageType] $direction';

    if (requestTime > 0) {
      logMessage += ' - ${requestTime}ms';
    }

    if (messageType == NostrMessageType.ok && eventId != null) {
      logMessage += ' - Event: $eventId, Accepted: ${accepted ?? false}';
      if (errorMessage?.isNotEmpty ?? false) {
        logMessage += ', Error: $errorMessage';
      }
    }

    logMessage += ' - Message: $message';

    // Use sessionId if provided, otherwise fall back to subscriptionId
    final id = sessionId ?? subscriptionId;
    if (id != null) {
      logMessage = '$id | $logMessage';
    }

    logMessage = '🚀 NETWORK_CALL | $logMessage';

    Logger.log(logMessage);
  }

  /// Starts timing a request to a relay
  void startRequestTimer(String relayUrl) {
    _requestTimers[relayUrl] = Stopwatch()..start();
  }

  /// Stops timing a request and logs the result
  void stopRequestTimer(String relayUrl) {
    final stopwatch = _requestTimers.remove(relayUrl);
    if (stopwatch != null) {
      stopwatch.stop();
    }
  }

  /// Associates a subscription ID with a relay URL
  void setSubscriptionId(String relayUrl, String subscriptionId) {
    _subscriptionIds[relayUrl] = subscriptionId;
  }

  /// Gets the subscription ID for a relay URL
  String? getSubscriptionId(String relayUrl) {
    return _subscriptionIds[relayUrl];
  }

  /// Clears subscription ID for a relay URL
  void clearSubscriptionId(String relayUrl) {
    _subscriptionIds.remove(relayUrl);
  }

  /// Associates an event ID with a relay URL for EVENT messages
  void setEventId(String relayUrl, String eventId) {
    _eventIds[relayUrl] = eventId;
  }

  /// Gets the event ID for a relay URL
  String? getEventId(String relayUrl) {
    return _eventIds[relayUrl];
  }

  /// Clears event ID for a relay URL
  void clearEventId(String relayUrl) {
    _eventIds.remove(relayUrl);
  }

  /// Stores a pending REQ message to be logged after first response
  void storePendingRequest(String relayUrl, RequestMessage request, String subscriptionId) {
    _pendingRequests[relayUrl] = request;
    setSubscriptionId(relayUrl, subscriptionId);
    startRequestTimer(relayUrl);
  }

  /// Logs a pending REQ message after receiving first response
  void logPendingRequest(String relayUrl) {
    final request = _pendingRequests.remove(relayUrl);
    if (request != null) {
      final subscriptionId = getSubscriptionId(relayUrl);
      final groupKey = '$relayUrl:$subscriptionId';
      final showPrefix = !_loggedGroups.contains(groupKey);
      if (showPrefix) {
        _loggedGroups.add(groupKey);
      }

      logNetworkCall(
        relayUrl: relayUrl,
        messageType: NostrMessageType.req,
        message: jsonEncode(request.toJson()),
        subscriptionId: subscriptionId,
        showPrefix: showPrefix,
      );
    }
  }

  /// Logs an EVENT message being sent
  void logEventSent(String relayUrl, EventMessage event) {
    // Use event ID only for deduplication (not relay-specific)
    if (_loggedEventIds.contains(event.id)) return;
    _loggedEventIds.add(event.id);

    setEventId(relayUrl, event.id);
    startRequestTimer(relayUrl);

    // Enhanced ID fallback chain: sessionId -> subscriptionId -> event.subscriptionId -> event.sig -> event.id
    final subscriptionId = getSubscriptionId(relayUrl);
    final id = subscriptionId ?? event.subscriptionId ?? event.sig ?? 'event:${event.id}';

    final groupKey = '$relayUrl:$id';
    final showPrefix = !_loggedGroups.contains(groupKey);
    if (showPrefix) {
      _loggedGroups.add(groupKey);
    }

    logNetworkCall(
      relayUrl: relayUrl,
      messageType: NostrMessageType.event,
      message: jsonEncode(event.toJson()),
      subscriptionId: id,
      showPrefix: showPrefix,
    );
  }

  /// Logs a REQ message being sent (stores for later logging)
  void logRequestSent(
    String relayUrl,
    RequestMessage request, {
    required String subscriptionId,
  }) {
    storePendingRequest(relayUrl, request, subscriptionId);
  }

  /// Logs an OK message being received
  void logOkReceived(String relayUrl, OkMessage okMessage) {
    stopRequestTimer(relayUrl);

    // Try to get subscription ID, fallback to event ID for EVENT responses
    var subscriptionId = getSubscriptionId(relayUrl);
    if (subscriptionId == null && okMessage.eventId.isNotEmpty) {
      // For EVENT responses, use the event ID as a pseudo subscription ID
      subscriptionId = 'event:${okMessage.eventId}';
    }

    final groupKey = '$relayUrl:$subscriptionId';
    final showPrefix = !_loggedGroups.contains(groupKey);
    if (showPrefix) {
      _loggedGroups.add(groupKey);
    }

    logNetworkCall(
      relayUrl: relayUrl,
      messageType: NostrMessageType.ok,
      message: jsonEncode(okMessage.toJson()),
      subscriptionId: subscriptionId,
      eventId: okMessage.eventId,
      accepted: okMessage.accepted,
      errorMessage: okMessage.message,
      showPrefix: showPrefix,
    );

    // Clear event ID after OK response
    if (okMessage.eventId.isNotEmpty) {
      clearEventId(relayUrl);
    }
  }

  /// Logs an EVENT message being received
  void logEventReceived(String relayUrl, EventMessage event) {
    // Use event ID only for deduplication (not relay-specific)
    if (_loggedEventIds.contains(event.id)) return;
    _loggedEventIds.add(event.id);

    logPendingRequest(relayUrl);

    // Enhanced ID fallback chain: sessionId -> subscriptionId -> event.subscriptionId -> event.sig -> event.id
    final subscriptionId = getSubscriptionId(relayUrl);
    final id = subscriptionId ?? event.subscriptionId ?? event.sig ?? 'event:${event.id}';

    final groupKey = '$relayUrl:$id';
    final showPrefix = !_loggedGroups.contains(groupKey);
    if (showPrefix) {
      _loggedGroups.add(groupKey);
    }

    logNetworkCall(
      relayUrl: relayUrl,
      messageType: NostrMessageType.event,
      message: jsonEncode(event.toJson()),
      subscriptionId: id,
      eventId: event.id,
      showPrefix: showPrefix,
    );
  }

  /// Logs a NOTICE message being received
  void logNoticeReceived(String relayUrl, NoticeMessage notice) {
    // Log pending REQ message if this is the first response
    logPendingRequest(relayUrl);

    final subscriptionId = getSubscriptionId(relayUrl);
    final groupKey = '$relayUrl:$subscriptionId';
    final showPrefix = !_loggedGroups.contains(groupKey);
    if (showPrefix) {
      _loggedGroups.add(groupKey);
    }

    stopRequestTimer(relayUrl);
    logNetworkCall(
      relayUrl: relayUrl,
      messageType: NostrMessageType.notice,
      message: jsonEncode(notice.toJson()),
      subscriptionId: getSubscriptionId(relayUrl),
      showPrefix: showPrefix,
    );
  }

  /// Logs a CLOSED message being received
  void logClosedReceived(String relayUrl, ClosedMessage closed) {
    // Log pending REQ message if this is the first response
    logPendingRequest(relayUrl);

    final subscriptionId = getSubscriptionId(relayUrl);
    final groupKey = '$relayUrl:$subscriptionId';
    final showPrefix = !_loggedGroups.contains(groupKey);
    if (showPrefix) {
      _loggedGroups.add(groupKey);
    }

    stopRequestTimer(relayUrl);
    logNetworkCall(
      relayUrl: relayUrl,
      messageType: NostrMessageType.closed,
      message: jsonEncode(closed.toJson()),
      subscriptionId: getSubscriptionId(relayUrl),
      showPrefix: showPrefix,
    );
    clearSubscriptionId(relayUrl);
  }

  /// Logs an EOSE message being received
  void logEoseReceived(String relayUrl, EoseMessage eose) {
    // Log pending REQ message if this is the first response
    logPendingRequest(relayUrl);

    final subscriptionId = getSubscriptionId(relayUrl);
    final groupKey = '$relayUrl:$subscriptionId';
    final showPrefix = !_loggedGroups.contains(groupKey);
    if (showPrefix) {
      _loggedGroups.add(groupKey);
    }

    stopRequestTimer(relayUrl);
    logNetworkCall(
      relayUrl: relayUrl,
      messageType: NostrMessageType.eose,
      message: jsonEncode(eose.toJson()),
      subscriptionId: getSubscriptionId(relayUrl),
      showPrefix: showPrefix,
    );
  }

  /// Logs an AUTH message being sent
  void logAuthSent(String relayUrl, AuthMessage auth) {
    startRequestTimer(relayUrl);

    final subscriptionId = getSubscriptionId(relayUrl);
    final groupKey = '$relayUrl:$subscriptionId';
    final showPrefix = !_loggedGroups.contains(groupKey);
    if (showPrefix) {
      _loggedGroups.add(groupKey);
    }

    logNetworkCall(
      relayUrl: relayUrl,
      messageType: NostrMessageType.auth,
      message: jsonEncode(auth.toJson()),
      subscriptionId: getSubscriptionId(relayUrl),
      showPrefix: showPrefix,
    );
  }
}
