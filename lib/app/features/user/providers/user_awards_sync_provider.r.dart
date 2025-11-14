// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/model/badges/badge_award.f.dart';
import 'package:ion/app/features/user/providers/badge_award_handler.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_awards_sync_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<void> userAwardsSync(Ref ref) async {
  final authState = await ref.watch(authProvider.future);
  if (!authState.isAuthenticated) {
    return;
  }

  final masterPubkey = ref.watch(currentPubkeySelectorProvider);
  final delegationComplete = ref.watch(delegationCompleteProvider).valueOrNull.falseOrValue;
  if (masterPubkey == null || !delegationComplete) {
    return;
  }

  final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (identityKeyName == null) {
    return;
  }

  final prefs = ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName));
  const doneKey = 'user_awards_sync_bootstrap_done_v2';
  final alreadyDone = prefs.getValue<bool>(doneKey) ?? false;
  if (alreadyDone) {
    return;
  }

  final handler = ref.read(badgeAwardHandlerProvider);
  final requestMessage = RequestMessage(
    filters: [
      RequestFilter(
        kinds: const [BadgeAwardEntity.kind],
        tags: {
          '#p': [
            [masterPubkey],
          ],
        },
      ),
    ],
  );

  await for (final event in ref.read(ionConnectNotifierProvider.notifier).requestEvents(
        requestMessage,
      )) {
    if (handler.canHandle(event)) {
      await handler.handle(event);
    }
  }
  await prefs.setValue(doneKey, true);
}
