// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:ion/app/utils/hex_encoding.dart';

class FatAddressV2TokenRecord {
  const FatAddressV2TokenRecord({
    required this.name,
    required this.symbol,
    required this.externalAddress,
    required this.externalType,
    this.bondingAddress,
    this.bondingBegin,
    this.bondingEnd,
    this.bondingSupply,
  });

  final String name;
  final String symbol;
  final String externalAddress;
  final int externalType;

  final String? bondingAddress;
  final BigInt? bondingBegin;
  final BigInt? bondingEnd;
  final BigInt? bondingSupply;
}

class FatAddressV2Data {
  const FatAddressV2Data({
    required this.tokens,
    required this.creatorAddress,
    this.affiliateAddress,
  });

  final List<FatAddressV2TokenRecord> tokens;
  final String creatorAddress;
  final String? affiliateAddress;

  Uint8List toBytes() {
    return const FatAddressV2Codec().encode(
      tokens: tokens,
      creatorAddress: creatorAddress,
      affiliateAddress: affiliateAddress,
    );
  }

  String toHex() => bytesToHex(toBytes());
}

class FatAddressV2Codec {
  const FatAddressV2Codec();

  static const int protocolVersion = 2;

  static const int _globalHeaderSize = 4;
  static const int _tokenHeaderSize = 8;
  static const int _evmAddressLength = 20;
  static const int _uint256Length = 32;

  static const int _maskCreatorAddress = 0x01;
  static const int _maskAffiliateAddress = 0x02;

  static const int _maskTokenBondingAddress = 0x01;
  static const int _maskTokenBondingPrices = 0x02;
  static const int _maskTokenBondingSupply = 0x04;

  Uint8List encode({
    required List<FatAddressV2TokenRecord> tokens,
    required String creatorAddress,
    String? affiliateAddress,
  }) {
    if (tokens.isEmpty || tokens.length > 2) {
      throw ArgumentError('FatAddress V2 must contain 1 or 2 token records.');
    }

    var globalMask = _maskCreatorAddress;
    final affiliate = affiliateAddress?.trim() ?? '';
    if (affiliate.isNotEmpty) {
      globalMask |= _maskAffiliateAddress;
    }

    final parts = <Uint8List>[];

    final globalHeader = Uint8List(_globalHeaderSize);
    globalHeader[0] = protocolVersion;
    globalHeader[1] = tokens.length;
    _writeUint16BE(globalHeader, offset: 2, value: globalMask);
    parts.add(globalHeader);

    for (final token in tokens) {
      parts.add(_encodeTokenRecord(token));
    }

    parts.add(_addressToBytes(creatorAddress));
    if ((globalMask & _maskAffiliateAddress) != 0) {
      parts.add(_addressToBytes(affiliate));
    }

    return _concat(parts);
  }

  Uint8List _encodeTokenRecord(FatAddressV2TokenRecord token) {
    final nameBytes = Uint8List.fromList(utf8.encode(token.name));
    final symbolBytes = Uint8List.fromList(utf8.encode(token.symbol));
    final extAddrBytes = Uint8List.fromList(utf8.encode(token.externalAddress));

    if (extAddrBytes.isEmpty) {
      throw const FormatException('externalAddress must not be empty');
    }

    _ensureFitsUint8Length(nameBytes.length, fieldName: 'name');
    _ensureFitsUint8Length(symbolBytes.length, fieldName: 'symbol');
    _ensureFitsUint8Length(extAddrBytes.length, fieldName: 'externalAddress');

    final externalType = token.externalType;
    if (externalType < 0 || externalType > 0xFF) {
      throw FormatException('externalType must fit uint8: $externalType');
    }

    var tokenMask = 0;
    final bondingAddress = token.bondingAddress?.trim() ?? '';
    if (bondingAddress.isNotEmpty) {
      tokenMask |= _maskTokenBondingAddress;
    }

    final begin = token.bondingBegin;
    final end = token.bondingEnd;
    if (begin != null || end != null) {
      if (begin == null || end == null) {
        throw const FormatException('bondingBegin and bondingEnd must be set together');
      }
      tokenMask |= _maskTokenBondingPrices;
    }

    final supply = token.bondingSupply;
    if (supply != null) {
      tokenMask |= _maskTokenBondingSupply;
    }

    final tokenHeader = Uint8List(_tokenHeaderSize);
    tokenHeader[0] = nameBytes.length;
    tokenHeader[1] = symbolBytes.length;
    tokenHeader[2] = extAddrBytes.length;
    tokenHeader[3] = externalType;
    _writeUint32BE(tokenHeader, offset: 4, value: tokenMask);

    final parts = <Uint8List>[
      tokenHeader,
      // Bonding address is always reserved (20 bytes), even if mask bit is not set.
      if (bondingAddress.isEmpty) Uint8List(_evmAddressLength) else _addressToBytes(bondingAddress),
    ];

    if ((tokenMask & _maskTokenBondingPrices) != 0) {
      parts
        ..add(_uint256ToBytes(begin!))
        ..add(_uint256ToBytes(end!));
    }

    if ((tokenMask & _maskTokenBondingSupply) != 0) {
      parts.add(_uint256ToBytes(supply!));
    }

    parts
      ..add(nameBytes)
      ..add(symbolBytes)
      ..add(extAddrBytes);

    return _concat(parts);
  }

  void _ensureFitsUint8Length(int length, {required String fieldName}) {
    if (length < 0 || length > 0xFF) {
      throw FormatException(
        'Invalid $fieldName length (expected <= 255 bytes UTF-8): $length',
      );
    }
  }

  Uint8List _uint256ToBytes(BigInt value) {
    if (value < BigInt.zero) {
      throw FormatException('uint256 must be non-negative: $value');
    }

    var hex = value.toRadixString(16);
    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }
    final raw = _hexToBytes(hex);
    if (raw.length > _uint256Length) {
      throw FormatException('uint256 overflow (expected <= 32 bytes): $value');
    }

    final out = Uint8List(_uint256Length)
      ..setRange(_uint256Length - raw.length, _uint256Length, raw);
    return out;
  }

  void _writeUint16BE(Uint8List out, {required int offset, required int value}) {
    if (value < 0 || value > 0xFFFF) {
      throw FormatException('uint16 overflow: $value');
    }
    out[offset] = (value >> 8) & 0xFF;
    out[offset + 1] = value & 0xFF;
  }

  void _writeUint32BE(Uint8List out, {required int offset, required int value}) {
    if (value < 0 || value > 0xFFFFFFFF) {
      throw FormatException('uint32 overflow: $value');
    }
    out[offset] = (value >> 24) & 0xFF;
    out[offset + 1] = (value >> 16) & 0xFF;
    out[offset + 2] = (value >> 8) & 0xFF;
    out[offset + 3] = value & 0xFF;
  }

  Uint8List _addressToBytes(String address) {
    final bytes = _hexToBytes(address);
    if (bytes.length != _evmAddressLength) {
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

  Uint8List _concat(List<Uint8List> parts) {
    var total = 0;
    for (final p in parts) {
      total += p.length;
    }

    final out = Uint8List(total);
    var offset = 0;
    for (final p in parts) {
      out.setRange(offset, offset + p.length, p);
      offset += p.length;
    }
    return out;
  }
}
