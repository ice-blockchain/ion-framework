// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
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

  // Listen to app lifecycle changes and dispose client when backgrounded.
  // This prevents "Bad file descriptor" errors that occur when the OS closes
  // the socket while the app is in the background.
  ref
    ..listen<AppLifecycleState>(appLifecycleProvider, (previous, next) {
      if (next != AppLifecycleState.resumed && previous == AppLifecycleState.resumed) {
        Logger.log(
          '[IonTokenAnalyticsClient] App backgrounded, disposing client',
        );
        client.dispose();
        // Invalidate this provider so a fresh client is created when the app resumes
        ref.invalidateSelf();
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

  final (delegationComplete, delegation, userAgent) = await (
    ref.watch(cacheDelegationCompleteProvider.future),
    ref.watch(currentUserCachedDelegationProvider.future),
    ref.watch(currentUserAgentProvider.future),
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
