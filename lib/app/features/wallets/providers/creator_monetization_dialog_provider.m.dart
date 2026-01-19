// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/auth/views/pages/required_bsc_wallet/creator_monetization_is_live_dialog.dart';
import 'package:ion/app/features/wallets/providers/bsc_wallet_check_provider.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/providers/route_location_provider.r.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'creator_monetization_dialog_provider.m.g.dart';
part 'creator_monetization_dialog_provider.m.freezed.dart';

@freezed
class CreatorMonetizationDialogParams with _$CreatorMonetizationDialogParams {
  factory CreatorMonetizationDialogParams({
    required bool? authenticated,
    required bool? delegationCompleted,
    required bool? hasBscWallet,
    required String? route,
  }) = _CreatorMonetizationDialogParams;
}

class CreatorMonetizationDialogService {
  CreatorMonetizationDialogService({
    required void Function() emitDialog,
  }) : _emitDialog = emitDialog;

  final void Function() _emitDialog;

  Future<void> process(CreatorMonetizationDialogParams params) async {
    if (params.authenticated != true) return;
    if (params.delegationCompleted != true) return;
    if (params.hasBscWallet ?? true) return;
    if (params.route != FeedRoute().location) return;

    _emitDialog();
  }
}

@riverpod
CreatorMonetizationDialogParams creatorMonetizationDialogParams(Ref ref) {
  final authenticated = ref.watch(authProvider);
  final delegationCompleted = ref.watch(delegationCompleteProvider);
  final bscWalletCheck = ref.watch(bscWalletCheckProvider);
  final route = ref.watch(routeLocationProvider);
  return CreatorMonetizationDialogParams(
    authenticated: authenticated.valueOrNull?.isAuthenticated,
    delegationCompleted: delegationCompleted.valueOrNull,
    hasBscWallet: bscWalletCheck.valueOrNull?.hasBscWallet,
    route: route,
  );
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

  ref.listen(creatorMonetizationDialogParamsProvider, (_, params) {
    service.process(params);
  });

  return service;
}
