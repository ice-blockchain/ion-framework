// SPDX-License-Identifier: ice License 1.0

import Foundation

// Shared storage over UserDefaults
class SharedStorage {
    static let appGroupKey = "APP_GROUP"

    let appGroupIdentifier: String

    private let userDefaults: UserDefaults

    enum SharedStorageError: Error {
        case noAppGroupIdentifier
        case noUserDefaultsForAppGroupIdentifier
    }

    init() throws {
        guard let appGroupIdentifier = Bundle.main.object(forInfoDictionaryKey: SharedStorage.appGroupKey) as? String
        else {
            throw SharedStorageError.noAppGroupIdentifier
        }

        self.appGroupIdentifier = appGroupIdentifier

        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            throw SharedStorageError.noUserDefaultsForAppGroupIdentifier
        }

        self.userDefaults = userDefaults
    }
    
    func getString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    func setString(_ string: String?, forKey key: String) {
        userDefaults.set(string, forKey: key)
    }
    
    func getInt(forKey key: String) -> Int {
        return userDefaults.integer(forKey: key)
    }
    
    func setInt(_ int: Int, forKey key: String) {
        userDefaults.set(int, forKey: key)
    }
        
    func getStringArray(forKey key: String) -> [String]? {
        userDefaults.stringArray(forKey: key)
    }
    
    func setStringArray(_ array: [String], forKey key: String) {
        userDefaults.set(array, forKey: key)
    }
}
