// SPDX-License-Identifier: ice License 1.0

import Foundation

private let fallbackLocale = Locale(identifier: "en_US")

enum TranslationError: Error {
    case notFound(locale: Locale)
    case fetchFailed(Error)
    case parseFailed(Error)
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
}

class Translator<T: TranslationWithVersion> {
    private let repository: TranslationsRepository<T>
    private let locale: Locale

    init(translationsRepository: TranslationsRepository<T>, appLocale: String?) {
        self.repository = translationsRepository
        self.locale = Locale(identifier: appLocale ?? fallbackLocale.identifier)
    }

    func translate<U>(_ selector: (T) -> U?) async -> U? {
        do {
            let translations = try await repository.getTranslations(locale: locale)
            if let translation = selector(translations) {
                return translation
            }

            // Try fallback locale if translation not found
            if locale != fallbackLocale {
                let fallbackTranslations = try await repository.getTranslations(locale: locale)
                return selector(fallbackTranslations)
            }

            return nil
        } catch {
            NSLog("[NSE] [Translator] Translation failed: \(error)")
            return nil
        }
    }
}

class TranslationsRepository<T: TranslationWithVersion & Decodable> {
    private let translationsPath = "ion-app_push-notifications_translations"

    private let ionOrigin: String
    private let appLocaleStorage: AppLocaleStorage
    private let cacheDirectory: URL
    let cacheMaxAge: TimeInterval

    init(
        ionOrigin: String,
        appLocaleStorage: AppLocaleStorage,
        cacheMaxAge: TimeInterval
    ) {
        self.ionOrigin = ionOrigin
        self.appLocaleStorage = appLocaleStorage
        self.cacheMaxAge = cacheMaxAge

        let translationCacheDirName = "TranslationCache"
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appLocaleStorage.storage.appGroupIdentifier)
        self.cacheDirectory =
            containerURL?.appendingPathComponent(translationCacheDirName, isDirectory: true)
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(translationCacheDirName)
    }

    func getTranslations(locale: Locale) async throws -> T {
        guard let languageCode = locale.languageCode ?? fallbackLocale.languageCode else {
            throw TranslationError.notFound(locale: locale)
        }

        let cacheFile = cacheDirectory.appendingPathComponent("\(translationsPath).\(languageCode).json")

        if let cachedTranslations = readValidCache(at: cacheFile) {
            return cachedTranslations
        }

        do {
            let translations = try await fetchTranslations(locale: locale)

            if translations == nil {
                if !FileManager.default.fileExists(atPath: cacheFile.path) {
                    throw TranslationError.notFound(locale: locale)
                }

                try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: cacheFile.path)
                return try readCache(at: cacheFile)
            }

            try saveToCache(data: translations!, at: cacheFile)
            return try JSONDecoder().decode(T.self, from: translations!)

        } catch {
            if FileManager.default.fileExists(atPath: cacheFile.path) {
                do {
                    return try readCache(at: cacheFile)
                } catch {
                    NSLog("[NSE] [Repository] Error reading fallback cache: \(error)")
                    throw error
                }
            }
            throw error
        }
    }

    private func readValidCache(at cacheFile: URL) -> T? {
        guard FileManager.default.fileExists(atPath: cacheFile.path) else { return nil }

        let attributes = try? FileManager.default.attributesOfItem(atPath: cacheFile.path)
        if let modificationDate = attributes?[.modificationDate] as? Date {
            let cacheDuration = Date().timeIntervalSince(modificationDate)
            if cacheDuration < cacheMaxAge {
                do {
                    return try readCache(at: cacheFile)
                } catch {
                    NSLog("[NSE] [Repository] Error reading cache: \(error)")
                }
            }
        }
        return nil
    }

    private func readCache(at cacheFile: URL) throws -> T {
        let data = try Data(contentsOf: cacheFile)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func saveToCache(data: Data, at cacheFile: URL) throws {
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try data.write(to: cacheFile)
        try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: cacheFile.path)
    }

    private func fetchTranslations(locale: Locale) async throws -> Data? {
        guard let languageCode = locale.languageCode ?? fallbackLocale.languageCode else {
            throw TranslationError.notFound(locale: locale)
        }

        let cacheVersion = appLocaleStorage.getCacheVersionKey(languageCode: languageCode)

        let urlString = "\(ionOrigin)/v1/config/\(translationsPath)_\(languageCode)"
        guard var urlComponents = URLComponents(string: urlString) else {
            throw TranslationError.invalidURL
        }

        urlComponents.queryItems = [URLQueryItem(name: "version", value: String(cacheVersion))]

        guard let url = urlComponents.url else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 3
        config.waitsForConnectivity = false

        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 204:  // No Content - use existing cache
                return nil

            case 200:
                if let translations = try? JSONDecoder().decode(T.self, from: data) {
                    appLocaleStorage.setCacheVersionKey(for: languageCode, with: translations.version)
                }
                return data

            default:
                throw TranslationError.httpError(statusCode: httpResponse.statusCode)
            }

        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                NSLog("[NSE] [Repository] Request timed out: \(url.absoluteString)")
            } else {
                NSLog("[NSE] [Repository] Network error: \(urlError.localizedDescription)")
            }
            throw TranslationError.fetchFailed(urlError)

        } catch {
            NSLog("[NSE] [Repository] Error fetching translations: \(error)")
            throw error
        }
    }
}
