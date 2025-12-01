// SPDX-License-Identifier: ice License 1.0

import 'dart:math';
import 'dart:typed_data';

import 'package:bip340/bip340.dart' as bip340;
import 'package:convert/convert.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';

class Secp256k1SchnorrKeyStore with EventSigner {
  Secp256k1SchnorrKeyStore._({
    required String privateKey,
    required String publicKey,
  })  : _privateKey = privateKey,
        _publicKey = publicKey;

  static Future<Secp256k1SchnorrKeyStore> generate() async {
    final privateKey = _generateRandomPrivateKey();
    final publicKey = bip340.getPublicKey(privateKey);
    return Secp256k1SchnorrKeyStore._(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  static Future<Secp256k1SchnorrKeyStore> fromPrivate(String privateKey) async {
    if (privateKey.length != 64) {
      throw ArgumentError('privateKey', 'Length must be 64 hex characters (32 bytes)');
    }
    final publicKey = bip340.getPublicKey(privateKey);
    return Secp256k1SchnorrKeyStore._(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  final String _privateKey;
  final String _publicKey;

  @override
  String get publicKey => _publicKey;

  @override
  String get privateKey => _privateKey;

  @override
  Future<String> sign({required String message}) async {
    return signBip340Schnorr(
      message: message,
      addPrefix: false,
    );
  }

  String signBip340Schnorr({
    required String message,
    bool addPrefix = true,
    String? aux,
  }) {
    final signature = bip340.sign(
      _privateKey,
      message,
      aux ?? _generateRandomAux(),
    );
    return '${addPrefix ? '$schnorrSignaturePrefix:' : ''}$signature';
  }

  /// Generates random auxiliary data for Schnorr signatures (32 bytes)
  String _generateRandomAux() {
    final random = Uint8List(32);
    final secureRandom = Random.secure();
    for (var i = 0; i < 32; i++) {
      random[i] = secureRandom.nextInt(256);
    }
    return hex.encode(random);
  }

  /// Generates a random 32-byte private key
  static String _generateRandomPrivateKey() {
    final random = Uint8List(32);
    final secureRandom = Random.secure();
    for (var i = 0; i < 32; i++) {
      random[i] = secureRandom.nextInt(256);
    }
    return hex.encode(random);
  }

  static const schnorrSignaturePrefix = 'schnorr/secp256k1';
}
