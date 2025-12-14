// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';

class LetsExchangeException extends IonSwapException {
  const LetsExchangeException([super.message]);
}

class LetsExchangePairUnavailableException extends LetsExchangeException {
  const LetsExchangePairUnavailableException({
    required this.fromCoin,
    required this.toCoin,
    this.fromNetwork,
    this.toNetwork,
    String? message,
  }) : super(message);

  final String fromCoin;
  final String toCoin;
  final String? fromNetwork;
  final String? toNetwork;

  @override
  String toString() {
    final networkInfo =
        fromNetwork != null && toNetwork != null ? ' ($fromNetwork -> $toNetwork)' : '';
    return 'LetsExchangePairUnavailableException: Pair $fromCoin-$toCoin$networkInfo is unavailable. ${message ?? ""}';
  }
}
