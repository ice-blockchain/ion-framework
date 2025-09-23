// SPDX-License-Identifier: ice License 1.0

class KeysStorage {
    static let currentPubkeyKey = "current_master_pubkey"
    static let currentIdentityKeyNameKey = "Auth:currentIdentityKeyName"

    let storage: SharedStorage

    init(storage: SharedStorage) {
        self.storage = storage
    }
    
    func getCurrentPubkey() -> String? {
        return storage.getString(forKey: KeysStorage.currentPubkeyKey)
    }

    func getCurrentIdentityKeyName() -> String? {
        return storage.getString(forKey: KeysStorage.currentIdentityKeyNameKey)
    }
}
