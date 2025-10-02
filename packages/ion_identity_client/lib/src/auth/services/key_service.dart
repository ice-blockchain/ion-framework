// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:ion_identity_client/src/auth/dtos/key_pair_data.dart';

class KeyService {
  const KeyService();

  // Generates an Ed25519 key pair
  Future<KeyPairData> generateKeyPair() async {
    final algorithm = crypto.Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final keyPairData = await keyPair.extract();
    final publicKey = keyPairData.publicKey;
    final privateKeyBytes = await keyPairData.extractPrivateKeyBytes();

    // Convert keys to PEM format
    final publicKeyPem = _encodeEd25519PublicKeyToPem(Uint8List.fromList(publicKey.bytes));
    final privateKeyPem = _encodeEd25519PrivateKeyToPem(Uint8List.fromList(privateKeyBytes));

    return KeyPairData(
      keyPair: keyPairData,
      publicKey: publicKey,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      privateKeyBytes: privateKeyBytes,
    );
  }

  /// Reconstructs a KeyPairData object from a hex-encoded Ed25519 private key (seed).
  Future<KeyPairData> reconstructKeyPairFromPrivateKeyBytes(
    String hexEncodedPrivateKeyBytes,
  ) async {
    final privateKeyBytes = Uint8List.fromList(hex.decode(hexEncodedPrivateKeyBytes));

    if (privateKeyBytes.length != 32) {
      throw ArgumentError(
        'Invalid private key seed length: expected 32 bytes, got ${privateKeyBytes.length}',
      );
    }

    final algorithm = crypto.Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
    final keyPairData = await keyPair.extract();
    final publicKey = keyPairData.publicKey;

    // Convert to PEM
    final publicKeyPem = _encodeEd25519PublicKeyToPem(Uint8List.fromList(publicKey.bytes));
    final privateKeyPem = _encodeEd25519PrivateKeyToPem(privateKeyBytes);

    return KeyPairData(
      keyPair: keyPairData,
      publicKey: publicKey,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      privateKeyBytes: privateKeyBytes,
    );
  }

  Future<KeyPairData> reconstructKeyPairFromEncryptedPrivateKey(
    String encryptedPrivateKey,
    String recoveryCode,
  ) async {
    // 1. Decrypt the private key to get the privateKeyPem
    final privateKeyPem = await decryptPrivateKey(encryptedPrivateKey, recoveryCode);

    // 2. Convert the PEM-encoded private key back to a SimpleKeyPairData
    final keyPairData = await pemToPrivateKey(privateKeyPem);

    // 3. Extract the public key and convert it to PEM format
    final publicKey = keyPairData.publicKey;
    final publicKeyPem = _encodeEd25519PublicKeyToPem(Uint8List.fromList(publicKey.bytes));

    // 4. Extract the private key bytes from the keyPairData
    final privateKeyBytes = await keyPairData.extractPrivateKeyBytes();

    // 5. Reconstruct the KeyPairData object
    return KeyPairData(
      keyPair: keyPairData,
      publicKey: publicKey,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      privateKeyBytes: privateKeyBytes,
    );
  }

  // Encrypts the private key using AES-GCM with a key derived from the recovery code
  Future<String> encryptPrivateKey(String privateKeyPem, String recoveryCode) async {
    // Generate a random salt
    final salt = crypto.SecretKeyData.random(length: 16).bytes;

    // Derive a key from the recovery code and salt using PBKDF2
    final pbkdf2 = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac(crypto.Sha256()),
      iterations: 100000, // Increased iterations for added security
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(recoveryCode)),
      nonce: salt,
    );

    // Encrypt the private key using AES-GCM
    final algorithm = crypto.AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      utf8.encode(privateKeyPem),
      secretKey: secretKey,
    );

    // Prepare the encrypted data for storage
    final encryptedData = {
      'salt': base64Encode(salt),
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    final encryptedDataJson = jsonEncode(encryptedData);
    return encryptedDataJson;
  }

  // Decrypts the private key using AES-GCM with a key derived from the recovery code
  Future<String> decryptPrivateKey(String encryptedPrivateKey, String recoveryKey) async {
    // Parse the encrypted data
    final encryptedData = jsonDecode(encryptedPrivateKey);
    final salt = base64Decode(encryptedData['salt'] as String);
    final nonce = base64Decode(encryptedData['nonce'] as String);
    final ciphertext = base64Decode(encryptedData['ciphertext'] as String);
    final macBytes = base64Decode(encryptedData['mac'] as String);

    // Derive the key from the recovery code and salt using PBKDF2
    final pbkdf2 = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac(crypto.Sha256()),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(recoveryKey)),
      nonce: salt,
    );

    // Decrypt the ciphertext using AES-GCM
    final algorithm = crypto.AesGcm.with256bits();
    final secretBox = crypto.SecretBox(
      ciphertext,
      nonce: nonce,
      mac: crypto.Mac(macBytes),
    );
    final decryptedData = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    final privateKeyPem = utf8.decode(decryptedData);
    return privateKeyPem;
  }

  // Convert PEM formatted private key to SimpleKeyPairData
  Future<crypto.SimpleKeyPairData> pemToPrivateKey(String privateKeyPem) async {
    // Remove PEM headers and footers
    final pemLines = privateKeyPem.split('\n').where((line) => !line.startsWith('-----')).toList();
    final base64Str = pemLines.join();
    final derBytes = base64.decode(base64Str);

    // Parse the ASN.1 structure
    final asn1Parser = ASN1Parser(derBytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    // Extract the privateKey field (OCTET STRING)
    final privateKeyOctetString = topLevelSeq.elements[2] as ASN1OctetString;

    // The privateKeyOctetString contains another OCTET STRING which contains the seed
    final innerParser = ASN1Parser(privateKeyOctetString.valueBytes());
    final innerOctetString = innerParser.nextObject() as ASN1OctetString;
    final privateKeyBytes = innerOctetString.valueBytes();

    // Now privateKeyBytes should be the 32-byte seed
    if (privateKeyBytes.length != 32) {
      throw ArgumentError(
        'Invalid private key length: expected 32 bytes, got ${privateKeyBytes.length}',
      );
    }

    final algorithm = crypto.Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);

    return keyPair.extract();
  }

  // Helper functions to encode keys to PEM format
  String _encodeEd25519PublicKeyToPem(Uint8List publicKeyBytes) {
    // OID for Ed25519
    final algorithmSeq = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromComponentString('1.3.101.112'));

    final publicKeyBitString = ASN1BitString(publicKeyBytes);

    final subjectPublicKeyInfo = ASN1Sequence()
      ..add(algorithmSeq)
      ..add(publicKeyBitString);

    final bytes = subjectPublicKeyInfo.encodedBytes;
    final base64Str = base64.encode(bytes);

    return '-----BEGIN PUBLIC KEY-----\n${_chunk(base64Str)}-----END PUBLIC KEY-----';
  }

  String _encodeEd25519PrivateKeyToPem(Uint8List privateKeyBytes) {
    // OID for Ed25519
    final algorithmSeq = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromComponentString('1.3.101.112'));

    final privateKeyOctetString = ASN1OctetString(privateKeyBytes);

    final privateKeyInfoSeq = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero)) // Version
      ..add(algorithmSeq)
      ..add(ASN1OctetString(privateKeyOctetString.encodedBytes));

    final bytes = privateKeyInfoSeq.encodedBytes;
    final base64Str = base64.encode(bytes);

    return '-----BEGIN PRIVATE KEY-----\n${_chunk(base64Str)}\n-----END PRIVATE KEY-----';
  }

  String _chunk(String str, [int size = 64]) {
    final sb = StringBuffer();
    for (var i = 0; i < str.length; i += size) {
      sb.writeln(str.substring(i, i + size > str.length ? str.length : i + size));
    }
    return sb.toString();
  }
}
