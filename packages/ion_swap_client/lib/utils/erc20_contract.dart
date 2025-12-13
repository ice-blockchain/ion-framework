// SPDX-License-Identifier: ice License 1.0

import 'package:web3dart/web3dart.dart';

class Erc20Contract {
  Erc20Contract._();

  static DeployedContract contractFor(EthereumAddress address) => DeployedContract(
        _erc20AbiParsed,
        address,
      );

  static const _erc20Abi = '''
[
  {"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},
  {"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"type":"function"},
  {"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"type":"function"}
]
''';

  static final ContractAbi _erc20AbiParsed = ContractAbi.fromJson(_erc20Abi, 'ERC20');
}
