// SPDX-License-Identifier: ice License 1.0

/// Enum representing the available signing algorithms for Nostr events
enum SigningAlgorithm {
  /// Ed25519 signing algorithm
  ed25519('curve25519'),

  /// secp256k1 Schnorr signing algorithm
  secp256k1Schnorr('secp256k1');

  const SigningAlgorithm(this.curveName);

  /// The curve name associated with this signing algorithm
  final String curveName;
}
