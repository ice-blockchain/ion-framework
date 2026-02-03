// SPDX-License-Identifier: ice License 1.0

class TokenExplorerUrlUtils {
  TokenExplorerUrlUtils._();

  /// Builds a BscScan token URL for mainnet or testnet.
  /// Mainnet: https://bscscan.com/token/<address>
  /// Testnet: https://testnet.bscscan.com/token/<address>
  static String buildBscscanTokenUrl({
    required String contractAddress,
    required bool isTestnet,
  }) {
    final host = isTestnet ? 'https://testnet.bscscan.com' : 'https://bscscan.com';
    return '$host/token/$contractAddress';
  }
}
