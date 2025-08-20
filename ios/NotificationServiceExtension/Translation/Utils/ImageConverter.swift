// SPDX-License-Identifier: ice License 1.0

import UIKit
import ImageIO

enum ImageConversionError: Error {
    case invalidURL
    case noData
    case decodeWebP
    case encodeJPEG
    case writeFailed(underlying: Error)
}

final class ImageConverter {
    func convertWebPToJPEG(
        webpURLString: String,
        outputJPEGURL: URL,
        quality: CGFloat = 0.7
    ) async throws -> URL {
        guard let webpURL = URL(string: webpURLString) else {
            throw ImageConversionError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: webpURL)
        guard !data.isEmpty else { throw ImageConversionError.noData }

        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ImageConversionError.decodeWebP
        }

        let image = UIImage(cgImage: cgImage)

        guard let jpegData = image.jpegData(compressionQuality: quality) else {
            throw ImageConversionError.encodeJPEG
        }

        do {
            try jpegData.write(to: outputJPEGURL, options: .atomic)
            return outputJPEGURL
        } catch {
            throw ImageConversionError.writeFailed(underlying: error)
        }
    }

    /// Same as above, but returns in-memory JPEG `Data`.
    func jpegData(
        fromWebPURLString webpURLString: String,
        quality: CGFloat = 0.7
    ) async throws -> Data {
        guard let webpURL = URL(string: webpURLString) else {
            throw ImageConversionError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: webpURL)
        guard !data.isEmpty else { throw ImageConversionError.noData }

        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ImageConversionError.decodeWebP
        }

        let image = UIImage(cgImage: cgImage)
        guard let jpegData = image.jpegData(compressionQuality: quality) else {
            throw ImageConversionError.encodeJPEG
        }
        return jpegData
    }

    /// Returns a `UIImage` created from the remote WebP (decoded) —
    /// you can then call `.jpegData(...)` yourself if needed.
    func jpegImage(
        fromWebPURLString webpURLString: String
    ) async throws -> UIImage {
        guard let webpURL = URL(string: webpURLString) else {
            throw ImageConversionError.invalidURL
        }
        let (data, _) = try await URLSession.shared.data(from: webpURL)
        guard !data.isEmpty else { throw ImageConversionError.noData }

        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ImageConversionError.decodeWebP
        }

        return UIImage(cgImage: cgImage)
    }
}
