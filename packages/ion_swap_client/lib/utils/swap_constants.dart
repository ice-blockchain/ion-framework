// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/models/bsc_fee_data.m.dart';

class SwapConstants {
  SwapConstants._();

  static const Duration delayAfterApproveDuration = Duration(seconds: 3);
  static BscFeeData defaultBscFeeData = BscFeeData(
    maxFeePerGas: BigInt.from(4500000000000),
    maxPriorityFeePerGas: BigInt.from(4500000000000),
  );

  static final BigInt keepAliveReserve = BigInt.from(500000000);

  static const List<int> okxEvmChainsIds = [
    137, // Polygon
    43114, // Avalanche C
    1, // Ethereum
    66, // OKTC
    56, // BNB Chain
    250, // Fantom
    42161, // Arbitrum
    10, // Optimism
    25, // Cronos
    324, // zkSync Era
    1030, // Conflux eSpace
    1101, // Polygon zkEVM
    59144, // Linea
    5000, // Mantle
    8453, // Base
    534352, // Scroll
    196, // X Layer
    169, // Manta Pacific
    1088, // Metis
    7000, // Zeta
    4200, // Merlin
    81457, // Blast
    146, // Sonic
    130, // Unichain
    9745, // Plasma
    143, // Monad
  ];
}
