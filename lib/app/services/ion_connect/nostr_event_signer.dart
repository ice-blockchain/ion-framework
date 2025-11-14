// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/ion_connect.dart';

/// Wrapper for EventSigner that ensures signatures are in Nostr format (no prefix)
class NostrEventSigner with EventSigner {
  NostrEventSigner(this._delegate);

  final EventSigner _delegate;

  @override
  String get publicKey => _delegate.publicKey;

  @override
  String get privateKey => _delegate.privateKey;

  @override
  Future<String> sign({required String message}) async {
    final signature = await _delegate.sign(message: message);
    
    // Strip prefix if present (e.g., "eddsa/curve25519:signature" -> "signature")
    // Nostr protocol expects plain hex signatures without any prefix
    if (signature.contains(':')) {
      return signature.split(':').last;
    }
    
    return signature;
  }
}

