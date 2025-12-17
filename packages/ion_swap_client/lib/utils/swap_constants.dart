// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/models/bsc_fee_data.m.dart';

class SwapConstants {
  SwapConstants._();

  static final BigInt maxFeePerGas = BigInt.from(20000000000);
  static final BigInt maxPriorityFeePerGas = BigInt.from(1000000000);
  static const Duration delayAfterApproveDuration = Duration(seconds: 3);
  static BscFeeData defaultBscFeeData = BscFeeData(
    maxFeePerGas: BigInt.from(4500000000000),
    maxPriorityFeePerGas: BigInt.from(4500000000000),
  );
}
