// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  NostrRelay? subscriptionRelay;
  NostrSubscription? subscription;

  void unsubscribe() {
    if (subscriptionRelay != null && subscription != null) {
      try {
        subscriptionRelay!.unsubscribe(subscription!.id);
      } catch (error, stackTrace) {
        SentryService.logException(error, stackTrace: stackTrace, tag: 'ion_connect_subscription');
        Logger.error(
          error,
          stackTrace: stackTrace,
          message: 'Caught error during unsubscribing from relay',
        );
      }
    }
  }

  final events = ref.watch(ionConnectNotifierProvider.notifier).requestEvents(
    requestMessage,
    actionSource: actionSource,
    subscriptionBuilder: (requestMessage, relay) {
      unsubscribe();
      subscriptionRelay = relay;
      subscription = relay.subscribe(requestMessage);

      return subscription!.messages;
    },
    onEose: onEndOfStoredEvents,
  );

  ref.onDispose(unsubscribe);

  return events;
}
