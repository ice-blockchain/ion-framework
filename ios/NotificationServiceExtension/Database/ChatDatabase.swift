// SPDX-License-Identifier: ice License 1.0

import Foundation
import SQLite3

/// Represents the message delivery status enum values from Dart
enum MessageDeliveryStatus: Int {
    case received = 0
    case read = 1
    case deleted = 2
}

final class ChatDatabase: DatabaseManager {
    init(keysStorage: KeysStorage) {
        super.init(
            keysStorage: keysStorage,
            logPrefix: "[CHATDB]",
            databaseNamePattern: "conversation_database_%@.sqlite"
        )
    }
    
    // MARK: - Conversation Methods
    
    /// Checks if a conversation exists in the database
    /// Equivalent to Dart's checkIfConversationExists method
    /// - Parameter conversationId: The ID of the conversation to check
    /// - Returns: True if the conversation exists, false otherwise
    func checkIfConversationExists(conversationId: String) -> Bool {
        guard tableExists("conversation_table") else {
            return false
        }
        
        let safeConversationId = conversationId.replacingOccurrences(of: "'", with: "''")
        
        let query = """
        SELECT id
        FROM conversation_table
        WHERE id = '\(safeConversationId)'
        LIMIT 1
        """
        
        guard let rows = executeQuery(query) else {
            NSLog("[NSE] [CHATDB] failed to check conversation existence for id: %@", conversationId)
            return false
        }
        
        return !rows.isEmpty
    }
}
