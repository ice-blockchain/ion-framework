// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/push_notifications/providers/account_notification_set_provider.r.dart';
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
  final accountNotificationSets =
      await ref.watch(currentUserAccountNotificationSetsProvider.future);

  final selectedTypes = accountNotificationSets
      .where((notificationSet) => notificationSet.data.userPubkeys.contains(userPubkey))
      .map((notificationSet) => notificationSet.data.type.toUserNotificationType())
      .toSet();

  final selected = selectedTypes.isEmpty ? {UserNotificationsType.none} : selectedTypes;

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

  final strategy = ref.watch(accountNotificationsSyncStrategyNotifierProvider);
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
