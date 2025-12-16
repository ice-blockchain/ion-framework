// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/wallets/data/repository/swap_disabled_repository.r.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_to_send_data.f.dart';
import 'package:ion/app/features/wallets/providers/send_asset_form_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/utils/swap_coin_identifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_disabled_notifier_provider.r.g.dart';

@riverpod
class SendDisabledNotifier extends _$SendDisabledNotifier {
  Timer? _timer;

  @override
  Future<bool> build() async {
    return true;
  }

  void startCheckSendDisabled() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkSendDisabled(),
    );
  }

  void stopCheckSendDisabled() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkSendDisabled() async {
    final formData = ref.watch(sendAssetFormControllerProvider);
    final coin = formData.assetData.as<CoinAssetToSendData>();
    final network = formData.network;
    final coinsGroup = coin?.coinsGroup;

    final isSellBuyCoinNull = network == null || coinsGroup == null;
    if (isSellBuyCoinNull) {
      state = const AsyncValue.data(false);
      return;
    }

    final isIonBsc = SwapCoinIdentifier.isIonBsc(coinsGroup, network);

    if (!isIonBsc) {
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
