// SPDX-License-Identifier: ice License 1.0

/// Enum representing the available signing algorithms for Nostr events
enum SigningAlgorithm {
  /// Ed25519 signing algorithm
  ed25519,

  /// secp256k1 Schnorr signing algorithm
  secp256k1Schnorr,
}
