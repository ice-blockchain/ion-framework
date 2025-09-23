// SPDX-License-Identifier: ice License 1.0

class AppLocaleStorage {
    static let appLocaleKey = "app_locale"

    let storage: SharedStorage

    init(storage: SharedStorage) {
        self.storage = storage
    }

    func getAppLocale() -> String? {
        return storage.getString(forKey: AppLocaleStorage.appLocaleKey)
    }

    func getCacheVersionKey(languageCode: String) -> Int {
        let cacheVersionKey = cacheVersionKey(for: languageCode)
        return storage.getInt(forKey: cacheVersionKey)
    }

    func setCacheVersionKey(for languageCode: String, with version: Int) {
        let cacheVersionKey = cacheVersionKey(for: languageCode)
        storage.setInt(version, forKey: cacheVersionKey)
    }

    private func cacheVersionKey(for languageCode: String) -> String {
        return "cache_version_\(languageCode)"
    }
}
