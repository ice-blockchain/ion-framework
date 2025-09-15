// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_sync_strategy_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/model/user_follow.f.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/toggle_follow_intent.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'follow_provider.r.g.dart';

@riverpod
OptimisticService<UserFollow> followService(Ref ref) {
  keepAliveWhenAuthenticated(ref);
  final manager = ref.watch(followManagerProvider);
  final initialFollows = ref.read(currentUserSyncFollowListProvider)?.masterPubkeys ?? [];
  final initialUserFollows = initialFollows.map((pubkey) {
    return UserFollow(pubkey: pubkey, following: true);
  }).toList();
  final service = OptimisticService<UserFollow>(manager: manager)..initialize(initialUserFollows);

  return service;
}

@riverpod
Stream<UserFollow?> followWatch(Ref ref, String pubkey) {
  final service = ref.watch(followServiceProvider);
  return service.watch(pubkey);
}

@riverpod
OptimisticOperationManager<UserFollow> followManager(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final strategy = ref.watch(followSyncStrategyProvider);
  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);

  final manager = OptimisticOperationManager<UserFollow>(
    syncCallback: strategy.send,
    onError: (_, __) async => true,
    enableLocal: localEnabled,
  );

  ref.onDispose(manager.dispose);

  return manager;
}

@riverpod
class ToggleFollowNotifier extends _$ToggleFollowNotifier {
  @override
  FutureOr<void> build() async {}

  Future<void> toggle(String pubkey) async {
    final service = ref.read(followServiceProvider);
    var current = service.get(pubkey);

    current ??= UserFollow(
      pubkey: pubkey,
      following: false,
    );

    await service.dispatch(ToggleFollowIntent(), current);

    await ref.read(toogleWatchNotifierProvider.notifier).toggle(
          following: !current.following,
          pubkey: pubkey,
        );
  }
}

@riverpod
class ToogleWatchNotifier extends _$ToogleWatchNotifier {
  @override
  String? build() => null;

  Future<void> toggle({
    required bool following,
    required String pubkey,
  }) async {
    if (following) {
      state = pubkey;
    } else {
      state = null;
    }
  }
}
