// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/services/global_long_lived_isolate.dart';
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
    final signatureParts = signature.split(':');
    if (signatureParts.length == 2) {
      final [prefix, signatureBody] = signatureParts;
      return switch (prefix) {
        Ed25519KeyStore.signaturePrefix => globalLongLivedIsolate.compute(
            (args) async {
              return verifyEddsaCurve25519SignatureFn(args);
            },
            (signatureBody: signatureBody, message: message, publicKey: publicKey),
          ),
        //TODO: impl a general fallback here
        _ => throw UnsupportedSignatureAlgorithmException(prefix)
      };
    }
    return super.verify(signature: signature, message: message, publicKey: publicKey);
  }
}

@pragma('vm:entry-point')
Future<bool> verifyEddsaCurve25519SignatureFn(
  ({String signatureBody, String message, String publicKey}) args,
) async {
  return Ed25519KeyStore.verifyEddsaCurve25519Signature(
    signature: args.signatureBody,
    message: args.message,
    publicKey: args.publicKey,
  );
}
