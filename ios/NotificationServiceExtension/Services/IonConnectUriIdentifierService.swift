// SPDX-License-Identifier: ice License 1.0

import Foundation

enum IonConnectProtocolIdentifierType: String, CaseIterable {
    case nprofile

    var name: String { rawValue }
}

class IonConnectUriIdentifierService {
    private let shareableIdentifiersPrefixes = [
      IonConnectProtocolIdentifierType.nprofile,
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
