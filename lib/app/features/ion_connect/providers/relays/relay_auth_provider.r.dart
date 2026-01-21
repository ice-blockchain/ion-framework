// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/core/providers/current_user_agent.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart' hide requestEvents;
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/auth_event.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_disliked_connect_urls_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relays_replica_delay_provider.m.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/utils/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relay_auth_provider.r.g.dart';

const _defaultTimeout = Duration(seconds: 30);

@riverpod
class RelayAuth extends _$RelayAuth {
  @override
  RelayAuthService build(IonConnectRelay relay) {
    final service = RelayAuthService(
      relay: relay,
      addDislikedConnectUrl: (connectUrl) {
        ref.read(relayDislikedConnectUrlsProvider(relay.url).notifier).add(connectUrl);
      },
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
        // In case of "already authenticated with a different public key" error,
        // we need to close the connection and force a fresh reconnection.
        // This can happen when switching accounts or when the relay has stale auth state.
        if (RelayAuthService.isAlreadyAuthenticatedWithDifferentKeyError(error)) {
          relay.close();
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

    final connectionSubscription = relay.socket.connection.listen((state) {
      // When the underlying websocket reconnects, any in-flight AUTH attempt is no longer valid.
      // If we keep the old completer, authenticateRelay() will "short circuit" and we will never
      // send a new AUTH for the new connection.
      if (state is Disconnected ||
          state is Disconnecting ||
          state is Reconnecting ||
          state is Reconnected) {
        final c = service.completer;
        if (c != null && !c.isCompleted) {
          c.completeError(
            const SocketException('Relay connection changed during authentication'),
          );
        }
        service.completer = null;
      }
    });
    ref.onDispose(connectionSubscription.cancel);

    return service;
  }
}

class RelayAuthService {
  RelayAuthService({
    required this.relay,
    required this.addDislikedConnectUrl,
    required this.createAuthEvent,
    required this.onError,
    this.completer,
  });

  final IonConnectRelay relay;

  final void Function(String connectUrl) addDislikedConnectUrl;

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

  Future<void> authenticateRelay() async {
    if (challenge == null || challenge!.isEmpty) throw AuthChallengeIsEmptyException();

    // Cases when we need to re-authenticate the relay:
    // * when we obtained a user delegation and need to re-authenticate with the `b` tag
    // * when BE requested re-authentication (in response to sending an event or starting a subscription)
    if (completer == null || completer!.isCompleted) {
      completer = Completer();
    } else {
      return completer!.future;
    }

    var didRetry = false;
    while (true) {
      try {
        final signedAuthEvent = await createAuthEvent(
          challenge: challenge!,
          relayUrl: Uri.parse(relay.url).toString(),
        );

        final authMessage = AuthMessage(
          challenge: jsonEncode(signedAuthEvent.toJson().last),
        );

        relay.sendMessage(authMessage);

        final okMessage = await relay.messages
            .where((message) => message is OkMessage)
            .cast<OkMessage>()
            .firstWhere((message) => signedAuthEvent.id == message.eventId)
            .timeout(
          _defaultTimeout,
          onTimeout: () {
            addDislikedConnectUrl(relay.connectUrl);
            relay.close();
            reportFailover(
              Exception(
                '[RELAY] Relay connection failover for logical URL: ${relay.url} and connect URL ${relay.connectUrl} with reason: AUTH OK timeout}',
              ),
              StackTrace.current,
              tag: 'relay_failover_auth_timeout',
            );
            throw SendEventException(
              'auth-required: AUTH OK timeout after ${_defaultTimeout.inSeconds}s',
            );
          },
        );

        if (!okMessage.accepted) {
          throw SendEventException(okMessage.message);
        }

        completer?.complete();
        return;
      } catch (error, st) {
        final shouldRetry = await onError(error);
        if (shouldRetry && !didRetry) {
          didRetry = true;
          continue;
        }

        // Make sure waiters get the failure and propagate it to the current caller.
        completer?.completeError(error, st);

        Error.throwWithStackTrace(error, st);
      }
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

  static bool isAlreadyAuthenticatedWithDifferentKeyError(Object? error) {
    return error is SendEventException &&
        error.code.toLowerCase().contains('already authenticated with a different public key');
  }
}
