// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/user/model/account_notifications_sets.f.dart';
import 'package:ion/app/features/user/model/user_notifications_type.dart';
import 'package:ion/app/features/user/optimistic_ui/account_notifications_sync_strategy_provider.r.dart';
import 'package:ion/app/features/user/optimistic_ui/model/account_notifications_option.f.dart';
import 'package:ion/app/features/user/optimistic_ui/toggle_account_notifications_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_notifications_provider.r.g.dart';

@riverpod
Future<List<AccountNotificationsOption>> loadInitialNotifications(
  Ref ref,
  String userPubkey,
) async {
  final currentMasterPubkey = ref.read(currentPubkeySelectorProvider);
  if (currentMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final notificationTypes = <UserNotificationsType>[];

  for (final type in UserNotificationsType.values) {
    if (type == UserNotificationsType.none) continue;

    final setType = AccountNotificationSetType.fromUserNotificationType(type);
    if (setType == null) {
      continue;
    }

    final accountNotificationSet = await ref.read(
      ionConnectEntityProvider(
        eventReference: ReplaceableEventReference(
          masterPubkey: currentMasterPubkey,
          kind: AccountNotificationSetEntity.kind,
          dTag: setType.dTagName,
        ),
      ).future,
    );

    if (accountNotificationSet is AccountNotificationSetEntity &&
        accountNotificationSet.data.userPubkeys.contains(userPubkey)) {
      notificationTypes.add(type);
    }
  }

  final selected =
      notificationTypes.isEmpty ? {UserNotificationsType.none} : notificationTypes.toSet();

  return [
    AccountNotificationsOption(
      userPubkey: userPubkey,
      selected: selected,
    ),
  ];
}

@riverpod
OptimisticOperationManager<AccountNotificationsOption> accountNotificationsManager(
  Ref ref,
  String userPubkey,
) {
  keepAliveWhenAuthenticated(ref);

  final strategy = ref.watch(accountNotificationsSyncStrategyProvider);
  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);

  final manager = OptimisticOperationManager<AccountNotificationsOption>(
    syncCallback: strategy.send,
    onError: (_, __) async => true,
    enableLocal: localEnabled,
  );

  ref.onDispose(manager.dispose);

  return manager;
}

@riverpod
OptimisticService<AccountNotificationsOption> accountNotificationsService(
  Ref ref,
  String userPubkey,
) {
  final manager = ref.watch(accountNotificationsManagerProvider(userPubkey));
  final service = OptimisticService<AccountNotificationsOption>(manager: manager)
    ..initialize(loadInitialNotifications(ref, userPubkey));

  return service;
}

@riverpod
Stream<AccountNotificationsOption?> accountNotificationsWatch(Ref ref, String userPubkey) {
  final service = ref.watch(accountNotificationsServiceProvider(userPubkey));

  return service.watch(userPubkey);
}

@riverpod
class ToggleAccountNotificationsNotifier extends _$ToggleAccountNotificationsNotifier {
  @override
  void build() {}

  Future<void> toggle({
    required String userPubkey,
    required UserNotificationsType option,
  }) async {
    final service = ref.read(accountNotificationsServiceProvider(userPubkey));

    var current = ref.read(accountNotificationsWatchProvider(userPubkey)).valueOrNull;

    current ??= AccountNotificationsOption(
      userPubkey: userPubkey,
      selected: {UserNotificationsType.none},
    );

    await service.dispatch(ToggleAccountNotificationsIntent(option), current);
  }
}
