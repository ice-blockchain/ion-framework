// SPDX-License-Identifier: ice License 1.0

import Foundation
import Compression

class Decompressor {
    static func decompress(_ base64String: String) throws -> Data {
        guard let data = Data(base64Encoded: base64String) else {
            throw DecompressionError.invalidBase64Data
        }
        
        return try decompressZlib(data: data)
    }
    
    static func decompressZlib(data: Data) throws -> Data {
        let mutableData = NSMutableData(data: data.subdata(in: 2..<data.count))
        
        do {
            try mutableData.decompress(using: .zlib)
            return mutableData as Data
        } catch let error {
            NSLog("[NSE] Decompression failed: \(error)")
            throw DecompressionError.decompressionFailed
        }
    }
}

enum DecompressionError: Error {
    case invalidBase64Data
    case decompressionFailed
    case jsonDataConversionFailed
}
