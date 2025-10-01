// SPDX-License-Identifier: ice License 1.0ˆ

import CryptoKit
import Foundation

class SignatureVerifier {
    static let ed25519SignaturePrefix = "eddsa/curve25519"

    /// Verifies a signature using Ed25519.
    /// - Parameters:
    ///   - publicKey: The public key in hex format
    ///   - message: The message to verify in hex format
    ///   - signature: The signature to verify, possibly with a prefix
    /// - Returns: True if the signature is valid, false otherwise
    static func verify(publicKey: String, message: String, signature: String) -> Bool {
        // Check if signature has the Ed25519 prefix
        let signatureParts = signature.split(separator: ":", maxSplits: 1).map { String($0) }

        if signatureParts.count == 2 && signatureParts[0] == ed25519SignaturePrefix {
            return verifyEd25519Signature(
                signature: signatureParts[1],
                message: message,
                publicKey: publicKey
            )
        }

        return false
    }

    /// Verifies an Ed25519 signature
    /// - Parameters:
    ///   - signature: The signature in hex format
    ///   - message: The message in hex format
    ///   - publicKey: The public key in hex format
    /// - Returns: True if the signature is valid, false otherwise
    static func verifyEd25519Signature(signature: String, message: String, publicKey: String) -> Bool {
        do {
            guard let signatureData = signature.hexadecimal,
                let messageData = message.hexadecimal,
                let publicKeyData = publicKey.hexadecimal
            else {
                return false
            }

            let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
            return publicKey.isValidSignature(signatureData, for: messageData)
        } catch {
            NSLog("[NSE] Ed25519 verification error: \(error)")
            return false
        }
    }
}

extension String {
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }

        guard data.count > 0 else { return nil }

        return data
    }
}
