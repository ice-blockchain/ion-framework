// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/services/shared_core_isolate.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/ion_connect/ed25519_key_store.dart';

class IonConnectSignatureVerifier extends SchnorrSignatureVerifier {
  IonConnectSignatureVerifier();

  @override
  Future<bool> verify({
    required String signature,
    required String message,
    required String publicKey,
  }) async {
    final result = await sharedCoreIsolate.compute(
      ionConnectSignatureVerifierFn,
      (signature: signature, message: message, publicKey: publicKey, fallbackVerifier: this),
    );
    return result;
  }
}

@pragma('vm:entry-point')
Future<bool> ionConnectSignatureVerifierFn(
  ({
    String signature,
    String message,
    String publicKey,
    SchnorrSignatureVerifier fallbackVerifier,
  }) args,
) async {
  final signatureParts = args.signature.split(':');
  if (signatureParts.length == 2) {
    final [prefix, signatureBody] = signatureParts;
    return switch (prefix) {
      Ed25519KeyStore.signaturePrefix => Ed25519KeyStore.verifyEddsaCurve25519Signature(
          signature: signatureBody,
          message: args.message,
          publicKey: args.publicKey,
        ),
      _ => throw UnsupportedSignatureAlgorithmException(prefix),
    };
  }

  return args.fallbackVerifier.verify(
    signature: args.signature,
    message: args.message,
    publicKey: args.publicKey,
  );
}
