// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';

class BscParser {
  static String parseBscAddress(String? address) {
    if (address == null || address.isEmpty) {
      throw const IonSwapException('BSC destination address is required for bridge');
    }

    // Validate Ethereum address format
    if (!address.startsWith('0x') || address.length != 42) {
      throw const IonSwapException('Invalid BSC destination address format');
    }

    return address;
  }
}
