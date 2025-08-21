// SPDX-License-Identifier: ice License 1.0

import Foundation

class Bech32Service {
    func encode(prefix: IonConnectProtocolIdentifierType, hexData: String, length: Int?) throws -> String {
        guard let data = hexData.hexadecimal else { throw Bech32ServiceError.decodeFailed(hexData) }
        
        let convertedData = try convertBits(data, fromBits: 8, toBits: 5, pad: true);
                
        return Bech32().encode(prefix.name, values: convertedData);
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

