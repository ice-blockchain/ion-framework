// SPDX-License-Identifier: ice License 1.0

import Clibsodium
import Compression
import CryptoKit
import Foundation
import NostrSDK
import Sodium

class EncryptedMessageService: NIP44v2Encrypting {
    enum DecryptionError: Error {
        case invalidPublicKey
        case invalidPrivateKey
        case keyConversionFailed
        case sharedSecretFailed
        case jsonDecodingFailed
        case sodiumInitializationFailed
        case hexDecodingFailed
    }

    private let keychainService: KeychainService
    private let pubkey: String

    init(keychainService: KeychainService, pubkey: String) {
        self.keychainService = keychainService
        self.pubkey = pubkey
    }

    /// Decrypts an E2E encrypted message using the private key from keychain
    /// - Parameter eventMessage: The encrypted event message to decrypt
    /// - Returns: The decrypted event message
    func decryptMessage(_ eventMessage: EventMessage) async throws -> EventMessage? {
        guard let privateKeyString = try keychainService.getPrivateKey() else {
            throw DecryptionError.invalidPrivateKey
        }

        let content = eventMessage.content
        let senderPubkey = eventMessage.pubkey

        // Parse compression algorithm from gift wrap tags
        let giftWrapCompressionAlgorithm = parseCompressionAlgorithm(from: eventMessage.tags)

        let seal = try decrypt(
            privateKeyString: privateKeyString,
            senderPubkey: senderPubkey,
            content: content,
            compressionAlgorithm: giftWrapCompressionAlgorithm
        )
        let sealEvent = try JSONDecoder().decode(EventMessage.self, from: seal!)

        // Parse compression algorithm from seal tags
        let sealCompressionAlgorithm = parseCompressionAlgorithm(from: sealEvent.tags)

        let rumor = try decrypt(
            privateKeyString: privateKeyString,
            senderPubkey: sealEvent.pubkey,
            content: sealEvent.content,
            compressionAlgorithm: sealCompressionAlgorithm
        )
        let rumorEvent = try JSONDecoder().decode(EventMessage.self, from: rumor!)

        return rumorEvent
    }

    /// Parses compression algorithm from event tags
    /// - Parameter tags: Array of tag arrays from the event
    /// - Returns: CompressionAlgorithm found in tags, defaults to .none
    private func parseCompressionAlgorithm(from tags: [[String]]) -> Algorithm? {
        for tag in tags {
            if let compressionTag = try? CompressionTag.fromTag(tag) {
                return compressionTag.algorithm
            }
        }
        
        return nil
    }

    private func decrypt(privateKeyString: String, senderPubkey: String, content: String, compressionAlgorithm: Algorithm?)
        throws -> Data?
    {
        guard let x25519PrivateKey = convertEd25519SkToX25519(privateKeyString),
            let x25519PublicKey = try convertEd25519PkToX25519(senderPubkey)
        else {
            NSLog("[NSE] Failed to convert keys from Ed25519 to X25519")
            throw DecryptionError.keyConversionFailed
        }

        let sharedSecretData = try getX25519SharedSecret(
            privateKeyHex: x25519PrivateKey,
            publicKeyHex: x25519PublicKey
        )

        guard let privateKey = PrivateKey(hex: x25519PrivateKey),
            let publicKey = PublicKey(hex: x25519PublicKey)
        else {
            throw DecryptionError.invalidPrivateKey
        }

        let decryptedContent = try decrypt(
            payload: content,
            privateKeyA: privateKey,
            publicKeyB: publicKey,
            customConversationKey: sharedSecretData,
            compressionAlgorithm: compressionAlgorithm
        )

        guard let data = decryptedContent.data(using: .utf8) else {
            NSLog("[NSE] Failed to convert decrypted content to data")
            return nil
        }

        return data
    }

    /// Converts Ed25519 public key to X25519 public key
    private func convertEd25519PkToX25519(_ hexPublicKey: String) throws -> String? {
        let edPkBytes = [UInt8](hex: hexPublicKey)

        if edPkBytes.count != crypto_sign_publickeybytes() {
            throw DecryptionError.invalidPublicKey
        }

        var curve25519Bytes = [UInt8](repeating: 0, count: crypto_box_publickeybytes())

        let result = crypto_sign_ed25519_pk_to_curve25519(&curve25519Bytes, edPkBytes)

        if result == 0 {
            return curve25519Bytes.toHexString()
        } else {
            return nil
        }
    }

    /// Converts Ed25519 private key to X25519 private key
    private func convertEd25519SkToX25519(_ hexPrivateKey: String) -> String? {
        let seed = [UInt8](hex: hexPrivateKey)

        if seed.count != crypto_sign_seedbytes() {
            return nil
        }

        var pk = [UInt8](repeating: 0, count: crypto_sign_publickeybytes())
        var sk = [UInt8](repeating: 0, count: crypto_sign_secretkeybytes())

        // Generate Ed25519 keypair from seed (same as TweetNaCl does)
        crypto_sign_seed_keypair(&pk, &sk, seed)

        var x25519Sk = [UInt8](repeating: 0, count: crypto_box_secretkeybytes())
        let result = crypto_sign_ed25519_sk_to_curve25519(&x25519Sk, sk)

        return result == 0 ? x25519Sk.toHexString() : nil
    }

    func getX25519SharedSecret(privateKeyHex: String, publicKeyHex: String) throws -> Data {
        guard let privateKeyData = privateKeyHex.hexadecimal else {
            throw DecryptionError.hexDecodingFailed
        }

        guard let publicKeyData = publicKeyHex.hexadecimal else {
            throw DecryptionError.hexDecodingFailed
        }

        let privateKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData)
        let publicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKeyData)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)

        // Extract the shared secret bytes
        let sharedSecretData = sharedSecret.withUnsafeBytes { Data($0) }

        // NIP-44 only uses HMAC-SHA256 (the extract step of HKDF), not the full HKDF
        // This matches the Dart implementation in Nip44.deriveConversationKey and hkdfExtract
        let salt = "nip44-v2".data(using: .utf8)!
        let key = SymmetricKey(data: salt)
        let hmac = HMAC<SHA256>.authenticationCode(for: sharedSecretData, using: key)

        return Data(hmac)
    }
}

// MARK: - Compression Support
enum CompressionAlgorithm: String, CaseIterable {
    case brotli = "brotli"
    case zlib = "zlib"
}

struct CompressionTag {
    static let tagName = "payload-compression"
    let value: CompressionAlgorithm

    var algorithm: Algorithm {
        switch value {
        case .brotli: return Algorithm.brotli
        case .zlib: return Algorithm.zlib
        }
    }

    static func fromTag(_ tag: [String]) throws -> CompressionTag? {
        guard tag.count >= 2 && tag[0] == tagName else {
            return nil
        }

        guard let algorithm = CompressionAlgorithm(rawValue: tag[1]) else { return nil }

        return CompressionTag(value: algorithm)
    }
}
