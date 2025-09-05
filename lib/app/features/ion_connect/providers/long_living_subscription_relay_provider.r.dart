// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/disliked_relay_urls_collection.f.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'long_living_subscription_relay_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<IonConnectRelay> longLivingSubscriptionRelay(
  Ref ref,
  ActionSource actionSource, {
  DislikedRelayUrlsCollection dislikedUrls = const DislikedRelayUrlsCollection({}),
}) async {
  onLogout(ref, () {
    ref.invalidateSelf();
  });

  final relay = await ref.read(relayPickerProvider.notifier).getActionSourceRelays(
        actionSource,
        actionType: ActionType.read,
        dislikedUrls: dislikedUrls,
      );
  unawaited(
    relay.keys.first.onClose.first.then((_) {
      ref.invalidateSelf();
    }),
  );

  return relay.keys.first;
}
