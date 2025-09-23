// SPDX-License-Identifier: ice License 1.0

import Foundation

final class ChatUserMetadataDatabase: DatabaseManager {
    init(keysStorage: KeysStorage) {
        super.init(
            keysStorage: keysStorage,
            logPrefix: "[CHATUSERMETADATADB]",
            databaseNamePattern: "user_profile_database_%@.sqlite"
        )
    }
    
    /// Fetches user metadata from the SQLite database for a given pubkey
    /// - Parameter pubkey: The pubkey of the user to fetch metadata for
    /// - Returns: UserMetadata if found, nil otherwise
    func getUserMetadataFromDatabase(pubkey: String) -> UserMetadata? {
        let query = "SELECT content FROM user_metadata_table WHERE master_pubkey = '\(pubkey)' ORDER BY created_at DESC LIMIT 1"

        guard let results = executeQuery(query) else {
            return nil
        }

        if results.isEmpty {
            NSLog("No user metadata found in database for pubkey: \(pubkey)")
            return nil
        }

        var content: String? = nil

        if let firstResult = results.first as? [String: Any], let contentValue = firstResult["content"] as? String {
            content = contentValue
        } else if let firstResult = results.first as? [Any], firstResult.count > 0 {
            if let contentDict = firstResult.first as? [String: String], let contentValue = contentDict["content"] {
                content = contentValue
            } else if let contentDict = firstResult.first as? [String: Any],
                let contentValue = contentDict["content"] as? String
            {
                content = contentValue
            }
        }

        guard let extractedContent = content else {
            return nil
        }

        guard let contentData = extractedContent.data(using: .utf8) else {
            NSLog("Failed to convert content string to data")
            return nil
        }

        do {
            let userData = try JSONDecoder().decode(
                UserDataEventMessageContent.self,
                from: contentData
            )

            // Create and return UserMetadata
            let metadata = UserMetadata(
                name: userData.name ?? "",
                displayName: userData.displayName ?? "",
                picture: userData.picture
            )

            return metadata
        } catch {
            NSLog("Error parsing user metadata: \(error)")
            return nil
        }
    }
}
