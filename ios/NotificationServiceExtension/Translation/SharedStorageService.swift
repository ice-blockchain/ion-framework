// SPDX-License-Identifier: ice License 1.0

import Foundation

class SharedStorageService {
    static let appGroupKey = "APP_GROUP"
    static let appLocaleKey = "app_locale"
    static let currentPubkeyKey = "current_master_pubkey"
    static let currentIdentityKeyNameKey = "Auth:currentIdentityKeyName"
    static let appBadgeCountKey = "app_badge_count"

    let appGroupIdentifier: String

    private let userDefaults: UserDefaults

    enum SharedStorageError: Error {
        case noAppGroupIdentifier
        case noUserDefaultsForAppGroupIdentifier
    }

    init() throws {
        guard let appGroupIdentifier = Bundle.main.object(forInfoDictionaryKey: SharedStorageService.appGroupKey) as? String
        else {
            throw SharedStorageError.noAppGroupIdentifier
        }

        self.appGroupIdentifier = appGroupIdentifier

        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            throw SharedStorageError.noUserDefaultsForAppGroupIdentifier
        }

        self.userDefaults = userDefaults
    }

    // MARK: - App locale

    func getAppLocale() -> String? {
        return userDefaults.string(forKey: SharedStorageService.appLocaleKey)
    }

    func getCacheVersionKey(languageCode: String) -> Int {
        let cacheVersionKey = cacheVersionKey(for: languageCode)
        return userDefaults.integer(forKey: cacheVersionKey)
    }

    func setCacheVersionKey(for languageCode: String, with version: Int) {
        let cacheVersionKey = cacheVersionKey(for: languageCode)
        userDefaults.set(version, forKey: cacheVersionKey)
    }

    // MARK: - Keys

    func getCurrentPubkey() -> String? {
        return userDefaults.string(forKey: SharedStorageService.currentPubkeyKey)
    }

    func getCurrentIdentityKeyName() -> String? {
        return userDefaults.string(forKey: SharedStorageService.currentIdentityKeyNameKey)
    }

    // MARK: - Badge Count

    func getBadgeCount() -> Int {
        return userDefaults.integer(forKey: SharedStorageService.appBadgeCountKey)
    }

    func setBadgeCount(_ count: Int) {
        userDefaults.set(count, forKey: SharedStorageService.appBadgeCountKey)
    }

    // MARK: - Private Helper Methods

    private func cacheVersionKey(for languageCode: String) -> String {
        return "cache_version_\(languageCode)"
    }
}
