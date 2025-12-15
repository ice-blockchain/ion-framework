// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/wallets/data/repository/swap_disabled_repository.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swap_disabled_notifier_provider.r.g.dart';

@riverpod
class SwapDisabledNotifier extends _$SwapDisabledNotifier {
  Timer? _timer;

  @override
  Future<bool> build() async {
    return true;
  }

  void startCheckSwapDisabled() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkSwapDisabled(),
    );
  }

  void stopCheckSwapDisabled() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkSwapDisabled() async {
    final swapNotifier = ref.read(swapCoinsControllerProvider);
    final sellCoin = swapNotifier.sellCoin;
    final sellNetwork = swapNotifier.sellNetwork;

    final isSellBuyCoinNull = sellCoin == null || sellNetwork == null;
    final isSellNetworkNotBsc = !(sellNetwork?.isBsc ?? false);
    final isSellCoinNotIon = sellCoin?.abbreviation.toUpperCase() != 'ION';

    if (isSellBuyCoinNull || isSellNetworkNotBsc || isSellCoinNotIon) {
      state = const AsyncValue.data(false);
      return;
    }

    final repo = await ref.watch(swapDisabledRepositoryProvider.future);
    try {
      final result = await repo.isIonTrade();
      state = AsyncValue.data(!result);
    } catch (_, __) {
      state = const AsyncValue.data(true);
    }
  }
}
