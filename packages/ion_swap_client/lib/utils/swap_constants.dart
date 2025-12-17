// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/models/bsc_fee_data.m.dart';

class SwapConstants {
  SwapConstants._();

  static const Duration delayAfterApproveDuration = Duration(seconds: 3);
  static BscFeeData defaultBscFeeData = BscFeeData(
    maxFeePerGas: BigInt.from(4500000000000),
    maxPriorityFeePerGas: BigInt.from(4500000000000),
  );
}
