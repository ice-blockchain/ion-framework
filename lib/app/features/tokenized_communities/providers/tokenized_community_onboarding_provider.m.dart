// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/pages/tokenized_community_onboarding_dialog/tokenized_community_onboarding_dialog.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tokenized_community_onboarding_provider.m.g.dart';
part 'tokenized_community_onboarding_provider.m.freezed.dart';

@freezed
class TokenizedCommunityOnboardingParams with _$TokenizedCommunityOnboardingParams {
  factory TokenizedCommunityOnboardingParams({
    required bool? authenticated,
    required bool? delegationCompleted,
    required bool? hasBscWallet,
    required bool? alreadyShown,
    required String? route,
  }) = _TokenizedCommunityOnboardingParams;
}

class TokenizedCommunityOnboardingService {
  TokenizedCommunityOnboardingService({
    required void Function() emitDialog,
    required Future<void> Function() setShown,
  })  : _emitDialog = emitDialog,
        _setShown = setShown;

  final void Function() _emitDialog;
  final Future<void> Function() _setShown;

  Future<void> process(TokenizedCommunityOnboardingParams params) async {
    if (params.authenticated != true) return;
    if (params.delegationCompleted != true) return;
    if (params.hasBscWallet != true) return;
    if (params.alreadyShown ?? true) return;
    if (params.route != FeedRoute().location) return;

    _emitDialog();
    await _setShown();
  }
}

@riverpod
TokenizedCommunityOnboardingParams tokenizedCommunityOnboardingParams(Ref ref) {
  final authenticated = ref.watch(authProvider);
  final delegationCompleted = ref.watch(delegationCompleteProvider);
  final bscWalletCheck = ref.watch(bscWalletCheckProvider);
  final alreadyShown = ref.watch(tokenizedCommunityOnboardingShownProvider);
  final route = ref.watch(routeLocationProvider);
  return TokenizedCommunityOnboardingParams(
    authenticated: authenticated.valueOrNull?.isAuthenticated,
    delegationCompleted: delegationCompleted.valueOrNull,
    hasBscWallet: bscWalletCheck.valueOrNull?.hasBscWallet,
    alreadyShown: alreadyShown,
    route: route,
  );
}

@riverpod
TokenizedCommunityOnboardingService? tokenizedCommunityOnboardingService(Ref ref) {
  final userPreferencesService = ref.watch(currentUserPreferencesServiceProvider);

  if (userPreferencesService == null) return null;

  final service = TokenizedCommunityOnboardingService(
    emitDialog: () {
      ref
          .read(uiEventQueueNotifierProvider.notifier)
          .emit(const TokenizedCommunityOnboardingDialogEvent());
    },
    setShown: () async {
      await ref.read(tokenizedCommunityOnboardingShownProvider.notifier).setShown();
    },
  );

  ref.listen(tokenizedCommunityOnboardingParamsProvider, (_, params) {
    service.process(params);
  });

  return service;
}

@riverpod
class TokenizedCommunityOnboardingShown extends _$TokenizedCommunityOnboardingShown {
  static const String _key = 'tokenized_community_onboarding_shown';

  @override
  bool? build() {
    final userPreferencesService = ref.watch(currentUserPreferencesServiceProvider);
    if (userPreferencesService == null) {
      return null;
    }
    return userPreferencesService.getValue<bool>(_key) ?? false;
  }

  Future<void> setShown() async {
    final userPreferencesService = ref.read(currentUserPreferencesServiceProvider);
    if (userPreferencesService == null) {
      return;
    }
    await userPreferencesService.setValue(_key, true);
    state = true;
  }
}
