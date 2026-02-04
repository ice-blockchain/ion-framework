// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/providers/env_provider.r.dart';

class TokenExplorerUrlUtils {
  TokenExplorerUrlUtils._();

  /// Builds a BscScan token URL for mainnet or testnet.
  /// Mainnet: https://bscscan.com/token/<address>
  /// Testnet: https://testnet.bscscan.com/token/<address>
  static String buildBscscanTokenUrl({required String contractAddress}) {
    final host = AppEnv.cryptocurrenciesBscScanHost;
    return '$host/token/$contractAddress';
  }
}
