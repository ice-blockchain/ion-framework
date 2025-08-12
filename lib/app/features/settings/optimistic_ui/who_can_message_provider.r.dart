// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';

import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/settings/model/privacy_options.dart';
import 'package:ion/app/features/settings/optimistic_ui/model/who_can_message_privacy_option.f.dart';
import 'package:ion/app/features/settings/optimistic_ui/toggle_who_can_message_intent.dart';
import 'package:ion/app/features/settings/optimistic_ui/who_can_message_sync_strategy_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'who_can_message_provider.r.g.dart';

@riverpod
Future<List<WhoCanMessagePrivacyOption>> loadInitialVisibility(Ref ref) async {
  final userMetadata = await ref.read(currentUserMetadataProvider.future);
  final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  if (userMetadata == null) {
    throw UserMetadataNotFoundException(currentUserMasterPubkey);
  }

  return [
    WhoCanMessagePrivacyOption(
      masterPubkey: currentUserMasterPubkey,
      visibility: UserVisibilityPrivacyOption.fromWhoCanSetting(userMetadata.data.whoCanMessageYou),
    ),
  ];
}

@riverpod
OptimisticOperationManager<WhoCanMessagePrivacyOption> whoCanMessageManager(Ref ref) {
  keepAliveWhenAuthenticated(ref);

  final strategy = ref.watch(whoCanMessageSyncStrategyProvider);
  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);

  final manager = OptimisticOperationManager<WhoCanMessagePrivacyOption>(
    syncCallback: strategy.send,
    onError: (_, __) async => true,
    enableLocal: localEnabled,
  );

  ref.onDispose(manager.dispose);

  return manager;
}

@riverpod
OptimisticService<WhoCanMessagePrivacyOption> whoCanMessageService(Ref ref) {
  final manager = ref.watch(whoCanMessageManagerProvider);
  final service = OptimisticService<WhoCanMessagePrivacyOption>(manager: manager)
    ..initialize(loadInitialVisibility(ref));

  return service;
}

@riverpod
Stream<WhoCanMessagePrivacyOption?> whoCanMessageWatch(Ref ref) {
  final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

  if (currentUserMasterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  final service = ref.watch(whoCanMessageServiceProvider);

  return service.watch(currentUserMasterPubkey);
}

@riverpod
class ToggleWhoCanMessageNotifier extends _$ToggleWhoCanMessageNotifier {
  @override
  void build() {}

  Future<void> toggle() async {
    final service = ref.read(whoCanMessageServiceProvider);

    var current = ref.read(whoCanMessageWatchProvider).valueOrNull;

    final currentUserMasterPubkey = ref.read(currentPubkeySelectorProvider);

    if (currentUserMasterPubkey == null) {
      throw UserMasterPubkeyNotFoundException();
    }

    current ??= WhoCanMessagePrivacyOption(
      visibility: UserVisibilityPrivacyOption.followedPeople,
      masterPubkey: currentUserMasterPubkey,
    );

    await service.dispatch(ToggleWhoCanMessageIntent(), current);
  }
}
