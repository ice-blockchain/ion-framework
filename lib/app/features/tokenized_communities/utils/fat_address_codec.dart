// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

class FatAddressCodec {
  const FatAddressCodec();

  static const int fixedHeaderSize = 64;
  static const String _zeroAddress = '0x0000000000000000000000000000000000000000';

  Uint8List encode({
    required String symbol,
    required String name,
    required String externalAddress,
    required String externalTypePrefix,
    required String creatorAddress,
    String? affiliateAddress,
    String? creatorTokenAddress,
  }) {
    final affiliate = affiliateAddress ?? _zeroAddress;
    final creatorToken = creatorTokenAddress ?? _zeroAddress;

    final prefix = externalTypePrefix.trim();
    if (prefix.isEmpty) {
      throw const FormatException('externalTypePrefix must not be empty');
    }
    if (prefix.length != 1) {
      throw FormatException('externalTypePrefix must be 1 character: $externalTypePrefix');
    }
    final externalType = prefix.codeUnitAt(0);

    final symbolBytes = Uint8List.fromList(utf8.encode(symbol));
    final nameBytes = Uint8List.fromList(utf8.encode(name));
    final externalAddressBytes = Uint8List.fromList(utf8.encode(externalAddress));

    if (externalAddressBytes.isEmpty) {
      throw const FormatException('externalAddress must not be empty');
    }

    _ensureFitsUint8Length(symbolBytes.length, fieldName: 'symbol');
    _ensureFitsUint8Length(nameBytes.length, fieldName: 'name');
    _ensureFitsUint8Length(externalAddressBytes.length, fieldName: 'externalAddress');

    // Header: 64 bytes
    // 0: symbolLen (1)
    // 1: nameLen (1)
    // 2: extAddrLen (1)
    // 3: extType (1)
    // 4: creator (20)
    // 24: affiliate (20)
    // 44: creatorToken (20)
    final header = Uint8List(fixedHeaderSize);
    header[0] = symbolBytes.length;
    header[1] = nameBytes.length;
    header[2] = externalAddressBytes.length;
    header[3] = externalType;

    header
      ..setAll(4, _addressToBytes(creatorAddress))
      ..setAll(24, _addressToBytes(affiliate))
      ..setAll(44, _addressToBytes(creatorToken));

    final result = Uint8List(
      fixedHeaderSize + symbolBytes.length + nameBytes.length + externalAddressBytes.length,
    )
      ..setAll(0, header)
      ..setAll(fixedHeaderSize, symbolBytes)
      ..setAll(fixedHeaderSize + symbolBytes.length, nameBytes)
      ..setAll(fixedHeaderSize + symbolBytes.length + nameBytes.length, externalAddressBytes);

    return result;
  }

  void _ensureFitsUint8Length(int length, {required String fieldName}) {
    if (length < 0 || length > 0xFF) {
      throw FormatException(
        'Invalid $fieldName length (expected <= 255 bytes UTF-8): $length',
      );
    }
  }

  Uint8List _addressToBytes(String address) {
    final bytes = _hexToBytes(address);
    if (bytes.length != 20) {
      throw FormatException('Invalid EVM address length (expected 20 bytes): $address');
    }
    return bytes;
  }

  Uint8List _hexToBytes(String hex) {
    var hexStr = hex.trim();
    if (hexStr.startsWith('0x')) {
      hexStr = hexStr.substring(2);
    }
    if (hexStr.length % 2 != 0) {
      hexStr = '0$hexStr';
    }
    final out = Uint8List(hexStr.length ~/ 2);
    for (var i = 0; i < hexStr.length; i += 2) {
      out[i ~/ 2] = int.parse(hexStr.substring(i, i + 2), radix: 16);
    }
    return out;
  }
}
