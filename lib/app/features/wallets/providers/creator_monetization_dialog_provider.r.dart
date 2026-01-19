// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/auth/views/pages/required_bsc_wallet/creator_monetization_is_live_dialog.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'creator_monetization_dialog_provider.r.g.dart';

class CreatorMonetizationDialogService {
  CreatorMonetizationDialogService({
    required void Function() emitDialog,
  }) : _emitDialog = emitDialog;

  bool? _authenticated;
  bool? _delegationCompleted;
  bool? _userHasBscWallet;
  String? _route;

  final void Function() _emitDialog;

  void onAuthenticated({required bool authenticated}) {
    _authenticated = authenticated;
    _maybeTrigger();
  }

  void onDelegationCompleted({required bool delegationCompleted}) {
    _delegationCompleted = delegationCompleted;
    _maybeTrigger();
  }

  void onUserHasBscWalletChanged({required bool hasBscWallet}) {
    _userHasBscWallet = hasBscWallet;
    _maybeTrigger();
  }

  void onRouteChanged(String value) {
    _route = value;
    _maybeTrigger();
  }

  Future<void> _maybeTrigger() async {
    if (_authenticated != true) return;
    if (_delegationCompleted != true) return;
    if (_userHasBscWallet ?? true) return;
    if (_route != FeedRoute().location) return;

    _emitDialog();
  }
}

@riverpod
CreatorMonetizationDialogService creatorMonetizationDialogService(Ref ref) {
  final service = CreatorMonetizationDialogService(
    emitDialog: () {
      ref
          .read(uiEventQueueNotifierProvider.notifier)
          .emit(const CreatorMonetizationIsLiveDialogEvent());
    },
  );

  ref
    ..listen<AsyncValue<AuthState>>(
      authProvider,
      fireImmediately: true,
      (_, next) {
        service.onAuthenticated(authenticated: next.valueOrNull?.isAuthenticated ?? false);
      },
    )
    ..listen<AsyncValue<bool?>>(
      delegationCompleteProvider,
      fireImmediately: true,
      (_, next) {
        service.onDelegationCompleted(delegationCompleted: next.valueOrNull ?? false);
      },
    )
    ..listen<String>(
      routeLocationProvider,
      fireImmediately: true,
      (_, next) {
        service.onRouteChanged(next);
      },
    )
    ..listen<AsyncValue<BscWalletCheckResult>>(
      bscWalletCheckProvider,
      fireImmediately: true,
      (_, next) {
        if (!next.isLoading && next.hasValue) {
          service.onUserHasBscWalletChanged(hasBscWallet: next.value!.hasBscWallet);
        }
      },
    );

  return service;
}
