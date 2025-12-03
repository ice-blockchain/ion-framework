// SPDX-License-Identifier: ice License 1.0

import Foundation

class IonConnectUriIdentifierService {
    private let shareableIdentifiersPrefixes = [
      IonConnectProtocolIdentifierType.nprofile,
      IonConnectProtocolIdentifierType.nevent,
      IonConnectProtocolIdentifierType.naddr,
    ];

    func encode(
        prefix: IonConnectProtocolIdentifierType,
        special: String,
    ) throws -> String {
        if !shareableIdentifiersPrefixes.contains(prefix) {
            throw IonConnectUriIdentifierError.notShareablePrefix(prefix, shareableIdentifiersPrefixes)
        }

        guard let data = special.hexadecimal else {
            throw IonConnectUriIdentifierError.decodeFailed(special)
        }

        let result = "00" + String(format: "%02x", data.count) + special

        return try Bech32Service().encode(prefix: prefix, hexData: result, length: result.count + 90)
    }

    /// Decode shareable identifiers per NIP-19 (nprofile, nevent, naddr)
    /// https://github.com/nostr-protocol/nips/blob/master/19.md
    func decodeShareableIdentifiers(payload: String) throws -> ShareableIdentifier {
        // Use Bech32Service to decode; length parity kept for Dart compatibility
        let decoded = try Bech32Service().decode(payload, length: payload.count)
        guard let prefix = IonConnectProtocolIdentifierType(rawValue: decoded.prefix) else {
            throw IonConnectUriIdentifierError.decodeFailed("Unknown HRP: \(decoded.prefix)")
        }
        // Ensure caller used a shareable identifier
        if !shareableIdentifiersPrefixes.contains(prefix) {
            throw IonConnectUriIdentifierError.notShareablePrefix(prefix, shareableIdentifiersPrefixes)
        }

        guard let dataBytes = _hexToBytes(decoded.data) else {
            throw IonConnectUriIdentifierError.decodeFailed("Invalid hex payload")
        }

        var idx = 0
        var special = ""
        var relays: [String] = []
        var author: String? = nil
        var kind: Int? = nil

        // Parse TLVs: (type:1, length:1, value:length)
        while idx < dataBytes.count {
            guard idx + 2 <= dataBytes.count else { break }
            let t = Int(dataBytes[idx]); idx += 1
            let l = Int(dataBytes[idx]); idx += 1
            guard idx + l <= dataBytes.count else { break }
            let v = Array(dataBytes[idx..<(idx + l)]); idx += l

            switch t {
            case 0:
                // special depends on HRP
                if prefix == .naddr {
                    special = String(bytes: v, encoding: .utf8) ?? ""
                } else {
                    special = _bytesToHex(v)
                }
            case 1:
                if let s = String(bytes: v, encoding: .utf8) { relays.append(s) }
            case 2:
                author = _bytesToHex(v)
            case 3:
                var k = 0
                for b in v { k = (k << 8) | Int(b) }
                kind = k
            default:
                continue
            }
        }

        return ShareableIdentifier(prefix: prefix,
                                   special: special,
                                   relays: relays,
                                   author: author,
                                   kind: kind)
    }
}

enum IonConnectUriIdentifierError: Swift.Error, LocalizedError {
    case notShareablePrefix(IonConnectProtocolIdentifierType, [IonConnectProtocolIdentifierType])
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case let .notShareablePrefix(prefix, allowed):
            return "\(prefix) not in \(allowed)"
        case let .decodeFailed(string):
            return "\(string) is not a valid hexadecimal string"
        }
    }
}

// MARK: - Hex helpers
private func _hexToBytes(_ hex: String) -> [UInt8]? {
    let len = hex.count
    guard len % 2 == 0 else { return nil }
    var bytes: [UInt8] = []
    bytes.reserveCapacity(len / 2)
    var idx = hex.startIndex
    while idx < hex.endIndex {
        let next = hex.index(idx, offsetBy: 2)
        guard next <= hex.endIndex else { return nil }
        let byteStr = hex[idx..<next]
        if let b = UInt8(byteStr, radix: 16) {
            bytes.append(b)
        } else {
            return nil
        }
        idx = next
    }
    return bytes
}

private func _bytesToHex(_ bytes: [UInt8]) -> String {
    bytes.map { String(format: "%02x", $0) }.joined()
}
