// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/dtos/private_key_data.j.dart';
import 'package:ion_identity_client/src/auth/services/key_service.dart';
import 'package:ion_identity_client/src/core/storage/biometrics_state_storage.dart';
import 'package:ion_identity_client/src/core/storage/private_key_storage.dart';
import 'package:ion_identity_client/src/signer/dtos/dtos.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_crypto/local_auth_crypto.dart';

enum SignatureEncryption { hex, base64Url }

class PasswordSigner {
  PasswordSigner({
    required this.config,
    required this.keyService,
    required this.privateKeyStorage,
    required this.biometricsStateStorage,
  });

  final KeyService keyService;
  final IONIdentityConfig config;
  final PrivateKeyStorage privateKeyStorage;
  final BiometricsStateStorage biometricsStateStorage;

  Future<CredentialRequestData> createCredentialInfo({
    required String challenge,
    required String password,
    required String username,
    required CredentialKind credentialKind,
  }) async {
    final keyPair = await keyService.generateKeyPair();

    final clientData = _buildClientData(
      challenge: challenge,
      origin: config.origin,
      clientDataType: ClientDataType.createKey,
    );

    final clientDataHash = _sha256Hash(utf8.encode(clientData));

    final credentialInfoFingerprint = _buildCredentialInfoFingerprint(
      clientDataHash: clientDataHash,
      publicKeyPem: keyPair.publicKeyPem,
    );

    final signature = await _signDataWithPrivateKey(
      data: credentialInfoFingerprint,
      privateKey: keyPair.keyPair,
      signatureEncryption: SignatureEncryption.hex,
    );

    final attestationData = _buildAttestationData(
      publicKeyPem: keyPair.publicKeyPem,
      signatureHex: signature,
    );

    final clientDataBase64Url = base64UrlEncode(utf8.encode(clientData));
    final attestationDataBase64Url = base64UrlEncode(utf8.encode(attestationData));

    final credId = _generateCredId(keyPair.publicKey);

    final encryptedPrivateKey = await keyService.encryptPrivateKey(
      keyPair.privateKeyPem,
      password,
    );

    if (credentialKind == CredentialKind.PasswordProtectedKey) {
      await Future.wait([
        privateKeyStorage.setPrivateKey(
          username: username,
          privateKeyData: PrivateKeyData(),
        ),
        _updateStateToCanSuggest(username),
      ]);
    }

    return CredentialRequestData(
      credentialInfo: CredentialInfo(
        credId: credId,
        clientData: clientDataBase64Url,
        attestationData: attestationDataBase64Url,
      ),
      credentialKind: credentialKind,
      encryptedPrivateKey: encryptedPrivateKey,
    );
  }

  Future<AssertionRequestData> signWithPassword({
    required String challenge,
    required String encryptedPrivateKey,
    required String password,
    required String credentialId,
    required CredentialKind credentialKind,
  }) async {
    try {
      final keyPair =
          await keyService.reconstructKeyPairFromEncryptedPrivateKey(encryptedPrivateKey, password);
      return _createCredentialAssertion(
        keyPair: keyPair,
        challenge: challenge,
        credentialId: credentialId,
        credentialKind: credentialKind,
      );
    } on crypto.SecretBoxAuthenticationError {
      throw const InvalidPasswordException();
    }
  }

  Future<AssertionRequestData> signWithBiometrics({
    required String challenge,
    required String credentialId,
    required String encryptedPrivateKey,
    required String username,
    required String localisedReason,
    required String localisedCancel,
    required CredentialKind credentialKind,
  }) async {
    final biometricsState = biometricsStateStorage.getBiometricsState(username: username);
    if (biometricsState != BiometricsState.enabled) {
      throw const BiometricsValidationException();
    }
    final biometricsEncryptedPassword = privateKeyStorage
        .getPrivateKey(
          username: username,
        )
        ?.biometricsEncryptedPassword;
    if (biometricsEncryptedPassword == null) {
      throw const BiometricsValidationException();
    }

    final localAuthCrypto = LocalAuthCrypto.instance;
    final password = await localAuthCrypto.authenticate(
      BiometricPromptInfo(
        title: localisedReason,
        negativeButton: localisedCancel,
      ),
      biometricsEncryptedPassword,
    );
    if (password == null) {
      throw const BiometricsValidationException();
    }

    final keyPair =
        await keyService.reconstructKeyPairFromEncryptedPrivateKey(encryptedPrivateKey, password);
    return _createCredentialAssertion(
      keyPair: keyPair,
      challenge: challenge,
      credentialId: credentialId,
      credentialKind: credentialKind,
    );
  }

  Future<void> rejectToUseBiometrics(String username) {
    return biometricsStateStorage.updateBiometricsState(
      username: username,
      biometricsState: BiometricsState.rejected,
    );
  }

  Future<void> enrollToUseBiometrics({
    required String username,
    required String password,
    required String localisedReason,
  }) async {
    try {
      final didAuthenticate = await _authWithBiometrics(localisedReason: localisedReason);
      if (didAuthenticate == false) {
        throw const BiometricsEnrollmentException();
      }
      final localAuthCrypto = LocalAuthCrypto.instance;
      final biometricsEncryptedPassword = await localAuthCrypto.encrypt(password);
      if (biometricsEncryptedPassword == null) {
        throw const BiometricsEnrollmentException();
      }
      await privateKeyStorage.setPrivateKey(
        username: username,
        privateKeyData: PrivateKeyData(biometricsEncryptedPassword: biometricsEncryptedPassword),
      );
      await biometricsStateStorage.updateBiometricsState(
        username: username,
        biometricsState: BiometricsState.enabled,
      );
    } catch (e) {
      await biometricsStateStorage.updateBiometricsState(
        username: username,
        biometricsState: BiometricsState.failed,
      );
      rethrow;
    }
  }

  Future<bool> _authWithBiometrics({
    required String localisedReason,
  }) async {
    final localAuth = LocalAuthentication();
    try {
      return await localAuth.authenticate(
        localizedReason: localisedReason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _updateStateToCanSuggest(String username) async {
    final biometricsAvailable = await isBiometricsAvailable();
    if (biometricsAvailable) {
      await biometricsStateStorage.updateBiometricsState(
        username: username,
        biometricsState: BiometricsState.canSuggest,
      );
    }
  }

  Future<bool> isBiometricsAvailable() async {
    final localAuth = LocalAuthentication();

    final results = await Future.wait<bool>([
      Future.value(false),
      localAuth.isDeviceSupported(),
    ]);

    final canCheckBiometrics = results[0];
    final isDeviceSupported = results[1];

    return canCheckBiometrics && isDeviceSupported;
  }

  String _buildClientData({
    required String challenge,
    required String origin,
    required ClientDataType clientDataType,
  }) {
    final clientDataMap = {
      'challenge': challenge,
      'crossOrigin': false,
      'origin': origin,
      'type': clientDataType.value,
    };

    // Ensure keys are sorted alphabetically
    final sortedClientDataMap = Map.fromEntries(
      clientDataMap.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)),
    );

    return jsonEncode(sortedClientDataMap);
  }

  // Computes SHA256 hash
  String _sha256Hash(List<int> data) {
    final hash = sha256.convert(data);
    return hash.toString();
  }

  // Builds the credential info fingerprint JSON string
  String _buildCredentialInfoFingerprint({
    required String clientDataHash,
    required String publicKeyPem,
  }) {
    final fingerprintMap = {
      'clientDataHash': clientDataHash,
      'publicKey': publicKeyPem,
    };

    // Ensure keys are sorted alphabetically
    final sortedFingerprintMap = Map.fromEntries(
      fingerprintMap.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)),
    );

    return jsonEncode(sortedFingerprintMap);
  }

  Future<String> _signDataWithPrivateKey({
    required String data,
    required crypto.SimpleKeyPairData privateKey,
    required SignatureEncryption signatureEncryption,
  }) async {
    final algorithm = crypto.Ed25519();

    final signature = await algorithm.sign(
      utf8.encode(data),
      keyPair: privateKey,
    );

    return switch (signatureEncryption) {
      SignatureEncryption.hex =>
        signature.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      SignatureEncryption.base64Url => base64UrlEncode(signature.bytes),
    };
  }

  // Builds the attestation data JSON string
  String _buildAttestationData({
    required String publicKeyPem,
    required String signatureHex,
  }) {
    final attestationDataMap = {
      'publicKey': publicKeyPem,
      'signature': signatureHex,
    };

    // Ensure keys are sorted alphabetically
    final sortedAttestationDataMap = Map.fromEntries(
      attestationDataMap.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)),
    );

    return jsonEncode(sortedAttestationDataMap);
  }

  String _generateCredId(crypto.SimplePublicKey publicKey) {
    final digest = sha256.convert(publicKey.bytes).bytes.sublist(0, 16);

    final base36Str = BigInt.parse(hex.encode(digest), radix: 16)
        .toRadixString(36)
        .toUpperCase()
        .padLeft(25, '0');

    final formattedStr =
        base36Str.replaceAllMapped(RegExp('.{5}'), (match) => '${match.group(0)}-');

    return formattedStr.endsWith('-')
        ? formattedStr.substring(0, formattedStr.length - 1)
        : formattedStr;
  }

  Future<AssertionRequestData> _createCredentialAssertion({
    required KeyPairData keyPair,
    required String challenge,
    required String credentialId,
    required CredentialKind credentialKind,
  }) async {
    final clientData = _buildClientData(
      challenge: challenge,
      origin: config.origin,
      clientDataType: ClientDataType.getKey,
    );

    final signature = await _signDataWithPrivateKey(
      data: clientData,
      privateKey: keyPair.keyPair,
      signatureEncryption: SignatureEncryption.base64Url,
    );

    return AssertionRequestData(
      kind: credentialKind,
      credentialAssertion: CredentialAssertionData(
        clientData: base64UrlEncode(utf8.encode(clientData)),
        credId: credentialId,
        signature: signature,
      ),
    );
  }
}
