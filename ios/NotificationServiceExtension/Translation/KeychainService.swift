// SPDX-License-Identifier: ice License 1.0

import Foundation
import Security

class KeychainService {
    private static let keychainGroupKey = "KEYCHAIN_GROUP"

    enum KeychainError: Error {
        case noAppGroupIdentifier
        case noKeychainGroupIdentifier
        case keychainAccessFailed(OSStatus)
        case dataConversionFailed
        case invalidData
    }

    private let currentIdentityKeyName: String
    private var privateKey: String?

    init(currentIdentityKeyName: String) {
        self.currentIdentityKeyName = currentIdentityKeyName

        do {
            _ = try self.getPrivateKey()
        } catch {
            NSLog("[NSE] Failed to preload private key: \(error)")
        }

    }

    /// Retrieves the private key from the keychain or from cache if available
    /// - Returns: The private key as a string
    /// - Throws: KeychainError if the key cannot be retrieved
    func getPrivateKey() throws -> String? {
        // Check if we need to refresh the key (identity changed or first load)

        if let privateKey = self.privateKey {
            return privateKey
        }

        return try fetchPrivateKeyFromKeychain(for: currentIdentityKeyName)
    }

    /// Fetches the private key from the keychain for a specific identity
    /// - Parameter identityKeyName: The identity key name to fetch the private key for
    /// - Returns: The private key as a string
    /// - Throws: KeychainError if the key cannot be retrieved from the keychain
    private func fetchPrivateKeyFromKeychain(for identityKeyName: String) throws -> String? {
        let storageKey = "\(identityKeyName)_ion_connect_key_store"

        guard
            let keychainGroupIdentifier = Bundle.main.object(forInfoDictionaryKey: KeychainService.keychainGroupKey) as? String
        else {
            throw KeychainError.noKeychainGroupIdentifier
        }

        // First try to access with kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        // This matches the accessibility setting from Flutter secure storage
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: storageKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: keychainGroupIdentifier,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        var item: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &item)

        // If access failed with specific accessibility, try without it
        // This provides fallback for items stored with different accessibility settings
        if status == errSecInteractionNotAllowed || status == errSecItemNotFound {
            NSLog("[NSE] First keychain access attempt failed with status \(status), trying fallback query")
            
            // Remove accessibility constraint and try again
            query.removeValue(forKey: kSecAttrAccessible as String)
            status = SecItemCopyMatching(query as CFDictionary, &item)
        }

        if status != errSecSuccess {
            NSLog("[NSE] Keychain access failed with status: \(status)")
            throw KeychainError.keychainAccessFailed(status)
        }

        guard let data = item as? Data else {
            throw KeychainError.dataConversionFailed
        }

        guard let privateKeyString = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionFailed
        }

        self.privateKey = privateKeyString

        return privateKeyString
    }
}
