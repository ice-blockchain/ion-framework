// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/current_user_agent.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart' hide requestEvents;
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/auth_event.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relays_replica_delay_provider.m.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/logger/websocket_tracker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_auth_provider.r.g.dart';

@riverpod
class RelayAuth extends _$RelayAuth {
  @override
  RelayAuthService build(IonConnectRelay relay) {
    final service = RelayAuthService(
      relay: relay,
      createAuthEvent: ({
        required String challenge,
        required String relayUrl,
      }) async {
        // Used cache delegation only because relay not authorized yet
        final delegationComplete = await ref.read(cacheDelegationCompleteProvider.future);
        final delegation = await ref.read(currentUserCachedDelegationProvider.future);
        final userRelays = await ref.read(currentUserRelaysProvider.future);
        final userAgent = await ref.read(currentUserAgentProvider.future);
        final relaysReplicaDelay = ref.read(relaysReplicaDelayProvider);

        final isRelayInUserRelays = userRelays?.urls.contains(relay.url) ?? false;
        final attachDelegation = delegationComplete.falseOrValue &&
            (!isRelayInUserRelays || relaysReplicaDelay.isDelayed);
        final attachUserRelays = isRelayInUserRelays && relaysReplicaDelay.isDelayed;

        final authEvent = AuthEvent(
          challenge: challenge,
          relay: relayUrl,
          userAgent: userAgent,
          userDelegation: attachDelegation ? delegation : null,
          userRelays: attachUserRelays ? userRelays : null,
        );

        return ref
            .read(ionConnectNotifierProvider.notifier)
            .sign(authEvent, includeMasterPubkey: delegationComplete.falseOrValue);
      },
      onError: (error) async {
        // In case of relay not authoritative error, we set the replica delay to attach
        // current user 10100 and 10002 events to the Auth event and attempting to re-authenticate.
        if (RelayAuthService.isRelayNotAuthoritativeError(error)) {
          ref.read(relaysReplicaDelayProvider.notifier).setDelay();
          return true;
        }
        return false;
      },
    );

    final authMessageSubscription = relay.messages.listen((message) {
      if (message is AuthMessage) {
        service.challenge = message.challenge;
      }
    });
    ref.onDispose(authMessageSubscription.cancel);

    return service;
  }
}

class RelayAuthService {
  RelayAuthService({
    required this.relay,
    required this.createAuthEvent,
    required this.onError,
    this.completer,
  });

  final IonConnectRelay relay;

  final Future<EventMessage> Function({required String challenge, required String relayUrl})
      createAuthEvent;

  final Future<bool> Function(Object? error) onError;

  Completer<void>? completer;

  String? challenge;

  Future<void> initRelayAuth() async {
    final signedAuthEvent = await createAuthEvent(
      challenge: 'init',
      relayUrl: Uri.parse(relay.url).toString(),
    );

    try {
      await relay.sendEvents([signedAuthEvent]);
    } catch (error) {
      if (isRelayAuthError(error)) {
        await authenticateRelay();
      } else {
        rethrow;
      }
    }
  }

  /// Handles relay authentication during send / request actions.
  ///
  /// Triggers the relay authentication process if relay requested it.
  /// Waits for ongoing authentication to complete before processing.
  Future<void> handleRelayAuthOnAction({
    required ActionSource actionSource,
    required Object? error,
  }) async {
    if (isRelayAuthError(error)) {
      if (!actionSource.anonymous) {
        await authenticateRelay();
      } else {
        throw AnonymousRelayAuthException();
      }
    }
    if (!actionSource.anonymous) {
      await completer?.future;
    }
  }

  Future<void> authenticateRelay({bool isRetry = false}) async {
    if (challenge == null || challenge!.isEmpty) throw AuthChallengeIsEmptyException();

    // Cases when we need to re-authenticate the relay:
    // * when we obtained a user delegation and need to re-authenticate with the `b` tag
    // * when BE requested re-authentication (in response to sending an event or starting a subscription)
    if (completer == null || completer!.isCompleted) {
      completer = Completer();
    } else {
      return completer!.future;
    }
    try {
      final signedAuthEvent = await createAuthEvent(
        challenge: challenge!,
        relayUrl: Uri.parse(relay.url).toString(),
      );

      final authMessage = AuthMessage(
        challenge: jsonEncode(signedAuthEvent.toJson().last),
      );

      // Log AUTH send
      final socketId = WebSocketTracker.getSocketId(relay) ?? -1;
      final host = WebSocketTracker.getHost(relay.url);
      final pubkey = signedAuthEvent.pubkey;
      Logger.info('NOSTR.WS.AUTH.SEND host=$host socket_id=$socketId ws_auth_pubkey=$pubkey');

      relay.sendMessage(authMessage);

      final okMessages = await relay.messages
          .where((message) => message is OkMessage)
          .cast<OkMessage>()
          .firstWhere((message) => signedAuthEvent.id == message.eventId);

      if (!okMessages.accepted) {
        // Log AUTH failure
        final errorMessage = okMessages.message.length > 80
            ? '${okMessages.message.substring(0, 80)}...'
            : okMessages.message;
        Logger.warning(
            'NOSTR.WS.AUTH.ERR host=$host socket_id=$socketId auth_result=err:$errorMessage');
        throw SendEventException(okMessages.message);
      }

      // Log AUTH success
      final okHost = WebSocketTracker.getHost(relay.url);
      final okSocketId = WebSocketTracker.getSocketId(relay) ?? -1;
      final okPubkey = signedAuthEvent.pubkey; // the pubkey that signed AUTH
      WebSocketTracker.setAuthOk(host: okHost, pubkey: okPubkey, socketId: okSocketId);
      Logger.info('NOSTR.WS.AUTH.OK host=$okHost socket_id=$okSocketId auth_result=ok');

      completer?.complete();
    } catch (error) {
      // Log AUTH error if not already logged
      if (error is! SendEventException) {
        final socketId = WebSocketTracker.getSocketId(relay);
        final host = WebSocketTracker.getHost(relay.url);
        final errorStr = error.toString();
        final errorMessage = errorStr.length > 80 ? '${errorStr.substring(0, 80)}...' : errorStr;
        Logger.warning(
            'NOSTR.WS.AUTH.ERR host=$host socket_id=$socketId auth_result=err:$errorMessage');
      }
      final shouldRetry = await onError(error);
      if (shouldRetry && !isRetry) {
        return authenticateRelay(isRetry: true);
      }
      completer?.completeError(error);
    }
  }

  static bool isRelayAuthError(Object? error) {
    final isSubscriptionAuthRequired = error is RelayRequestFailedException &&
        error.event is ClosedMessage &&
        (error.event as ClosedMessage).message.startsWith('auth-required');
    final isSendEventAuthRequired =
        error is SendEventException && error.code.startsWith('auth-required');
    return isSubscriptionAuthRequired || isSendEventAuthRequired;
  }

  static bool isRelayNotAuthoritativeError(Object? error) {
    return error is SendEventException && error.code.startsWith('relay-is-not-authoritative');
  }

  static bool isRelayAuthoritativeError(Object? error) {
    return error is SendEventException && error.code.startsWith('relay-is-authoritative');
  }
}
