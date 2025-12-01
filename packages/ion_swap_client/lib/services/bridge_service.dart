// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/models/swap_coin_parameters.m.dart';
import 'package:ion_swap_client/repositories/relay_api_repository.dart';

class BridgeService {
  BridgeService({
    required RelayApiRepository relayApiRepository,
  }) : _relayApiRepository = relayApiRepository;

  final RelayApiRepository _relayApiRepository;

  // TODO(ice-erebus): implement actual logic (this one in PR with UI)
  Future<void> tryToBridge(SwapCoinParameters swapCoinData) async {
    await _relayApiRepository.getQuote();
  }
}
