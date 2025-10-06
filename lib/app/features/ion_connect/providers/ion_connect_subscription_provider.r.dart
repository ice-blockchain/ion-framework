// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/app_lifecycle_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/sentry/sentry_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_subscription_provider.r.g.dart';

@riverpod
Raw<Stream<EventMessage>> ionConnectEventsSubscription(
  Ref ref,
  RequestMessage requestMessage, {
  ActionSource actionSource = const ActionSourceCurrentUser(),
  VoidCallback? onEndOfStoredEvents,
}) {
  final events = ref.watch(ionConnectNotifierProvider.notifier).requestEvents(
    requestMessage,
    actionSource: actionSource,
    subscriptionBuilder: (requestMessage, relay) {
      final subscription = relay.subscribe(requestMessage);
      try {
        ref
          ..onDispose(() => relay.unsubscribe(subscription.id))
          ..listen(appLifecycleProvider, (previous, next) {
            if (next != AppLifecycleState.resumed) {
              Logger.log(
                '[GLOBAL_SUBSCRIPTION] unsubscribe on lifecycle change - ion connect subscription',
              );
              relay.unsubscribe(subscription.id);
            }
          });
      } catch (error, stackTrace) {
        SentryService.logException(error, stackTrace: stackTrace, tag: 'ion_connect_subscription');
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: 'Caught error during unsubscribing from relay',
        );
      }
      return subscription.messages;
    },
    onEose: onEndOfStoredEvents,
  );

  return events;
}
