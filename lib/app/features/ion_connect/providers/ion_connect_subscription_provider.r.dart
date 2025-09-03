// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/services/logger/logger.dart';
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
        ref.onDispose(() => relay.unsubscribe(subscription.id));
      } on Exception catch (ex) {
        Logger.error('Caught error during unsubscribing from relay: $ex');
      }
      return subscription.messages;
    },
    onEose: onEndOfStoredEvents,
  );

  return events;
}
