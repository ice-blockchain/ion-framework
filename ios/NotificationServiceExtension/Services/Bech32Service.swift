// SPDX-License-Identifier: ice License 1.0

import Foundation

class Bech32Service {
    func encode(prefix: IonConnectProtocolIdentifierType, hexData: String, length: Int?) throws -> String {
        guard let data = hexData.hexadecimal else { throw Bech32ServiceError.decodeFailed(hexData) }

        let convertedData = try convertBits(data, fromBits: 8, toBits: 5, pad: true);

        return Bech32().encode(prefix.name, values: convertedData);
    }

    /// Decode a Bech32 string back to (prefix HRP, hex data).
    /// Mirrors the Dart implementation: returns the human-readable part and the payload as a hex string.
    /// `length` is accepted for API parity but is not required by the current Bech32 implementation.
    func decode(_ bech32Data: String, length: Int? = nil) throws -> (prefix: String, data: String) {
        // Expect Bech32().decode to return a tuple (hrp:String, values:Data) or similar.
        // If your Bech32.decode signature differs, adapt the destructuring accordingly.
        let (hrp, values) = try Bech32().decode(bech32Data)
        // Convert 5-bit groups back to 8-bit bytes (no padding on decode).
        let converted = try convertBits(values, fromBits: 5, toBits: 8, pad: false)
        // Hex-encode the byte payload.
        let hexString = converted.bytes.map { String(format: "%02x", $0) }.joined()
        return (prefix: hrp.lowercased(), data: hexString)
    }

    func convertBits(_ data: Data, fromBits: Int, toBits: Int, pad: Bool) throws -> Data {
        var acc = 0, bits = 0
        let maxv = (1 << toBits) - 1
        var result: [UInt8] = []
        for v in data.bytes {
            let value = Int(v)
            if (value >> fromBits) != 0 { throw Bech32ServiceError.invalidValue(value) }
            acc = (acc << fromBits) | value
            bits += fromBits
            while bits >= toBits {
                bits -= toBits
                result.append(UInt8((acc >> bits) & maxv))
            }
        }
        if pad {
            if bits > 0 { result.append(UInt8((acc << (toBits - bits)) & maxv)) }
        } else if bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0 {
            throw Bech32ServiceError.invalidValue(bits)
        }

        return Data(result)
    }
}

enum Bech32ServiceError: Swift.Error, LocalizedError {
    case decodeFailed(String)
    case invalidValue(Int)

    var errorDescription: String? {
        switch self {
        case let .decodeFailed(string):
            return "\(string) is not a valid hexadecimal string"
        case let .invalidValue(value):
            return "Invalid value: \(value)"
        }
    }
}

