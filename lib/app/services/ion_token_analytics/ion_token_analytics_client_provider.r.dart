// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/components/verify_identity/passkey_dialog_state.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/core/providers/current_user_agent.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/auth_event.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/services/ion_token_analytics/token_analytics_logger.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_token_analytics_client_provider.r.g.dart';

@riverpod
Future<IonTokenAnalyticsClient> ionTokenAnalyticsClient(Ref ref) async {
  keepAliveWhenAuthenticated(ref);
  final baseUrl =
      ref.watch(envProvider.notifier).get<String>(EnvVariable.ION_TOKEN_ANALYTICS_BASE_URL);

  final authToken = await ref.watch(tokenAnalyticsAuthTokenProvider);

  final client = await IonTokenAnalyticsClient.create(
    options: IonTokenAnalyticsClientOptions(
      baseUrl: baseUrl,
      authToken: authToken,
      logger: TokenAnalyticsLogger(),
    ),
  );

  // Listen to app lifecycle changes and force-disconnect when backgrounded.
  // This prevents "Bad file descriptor" errors that occur when the OS closes
  // the socket while the app is in the background.
  // We use forceDisconnect (not dispose) so the client stays alive and
  // ReconnectingSse can transparently re-establish subscriptions on resume,
  // avoiding a provider rebuild cascade.
  ref
    ..listen<AppLifecycleState>(appLifecycleProvider, (previous, next) {
      if (next == AppLifecycleState.hidden && previous != AppLifecycleState.paused) {
        // Don't disconnect during passkey auth - Face ID causes 'inactive' state
        // which triggers cleanup cascade that blocks passkey callback
        if (GlobalPasskeyDialogState.isShowing) {
          Logger.log(
            '[IonTokenAnalyticsClient] Skipping disconnect - passkey auth in progress',
          );
          return;
        }
        Logger.log(
          '[IonTokenAnalyticsClient] App backgrounded, force-disconnecting client',
        );
        client.forceDisconnect();
      }
    })

    // Ensure cleanup when provider is disposed
    ..onDispose(() {
      Logger.log(
        '[IonTokenAnalyticsClient] Provider disposed, disposing client',
      );
      client.dispose();
    });

  return client;
}

@riverpod
Raw<Future<String?>> tokenAnalyticsAuthToken(Ref ref) async {
  keepAliveWhenAuthenticated(ref);
  ref.watch(currentIdentityKeyNameSelectorProvider);

  final (delegationComplete, delegation, userAgent) = await (
    ref.read(cacheDelegationCompleteProvider.future),
    ref.read(currentUserCachedDelegationProvider.future),
    ref.read(currentUserAgentProvider.future),
  ).wait;

  final authEvent = AuthEvent(
    challenge: '',
    relay: '',
    userAgent: userAgent,
    userDelegation: delegation,
  );

  final authEventMessage = await ref
      .read(ionConnectNotifierProvider.notifier)
      .sign(authEvent, includeMasterPubkey: delegationComplete);

  final jsonPayload = jsonEncode(authEventMessage.jsonPayload);
  final jsonPayloadBytes = utf8.encode(jsonPayload);
  final authToken = base64Encode(jsonPayloadBytes);
  return authToken;
}
