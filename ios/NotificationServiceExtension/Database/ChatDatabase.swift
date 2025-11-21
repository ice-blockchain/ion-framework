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
    
    /// Gets muted conversation IDs from the database
    /// Based on Dart's mutedConversationIds provider logic
    /// - Parameter currentUserMasterPubkey: The current user's master pubkey
    /// - Returns: Array of muted conversation IDs
    func getMutedConversationIds(currentUserMasterPubkey: String) -> [String] {
        // Check if the required tables exist
        guard tableExists("event_message_table") else {
            NSLog("[NSE] [CHATDB] event_message_table not found for muted conversations")
            return []
        }
        
        let safePubkey = currentUserMasterPubkey.replacingOccurrences(of: "'", with: "''")
        
        // Query for MuteSetEntity (kind 30007) with chat conversations d-tag
        // This matches the Dart logic: kinds: [MuteSetEntity.kind], authors: [currentUserMasterPubkey]
        let query = """
        SELECT content
        FROM event_message_table
        WHERE kind = 30007
        AND master_pubkey = '\(safePubkey)'
        AND content LIKE '%"d":["chat_conversations"]%'
        ORDER BY created_at DESC
        LIMIT 1
        """
        
        guard let rows = executeQuery(query), let row = rows.first else {
            NSLog("[NSE] [CHATDB] no muted conversations found")
            return []
        }
        
        guard let content = row["content"] as? String else {
            NSLog("[NSE] [CHATDB] invalid content format for muted conversations")
            return []
        }
        
        // Parse the JSON content to extract muted conversation data
        return parseMutedConversationIds(from: content, currentUserMasterPubkey: currentUserMasterPubkey)
    }
    
    /// Parses muted conversation IDs from MuteSetEntity JSON content
    /// - Parameters:
    ///   - content: JSON content from the MuteSetEntity
    ///   - currentUserMasterPubkey: Current user's master pubkey
    /// - Returns: Array of muted conversation IDs
    private func parseMutedConversationIds(from content: String, currentUserMasterPubkey: String) -> [String] {
        guard let data = content.data(using: .utf8) else {
            NSLog("[NSE] [CHATDB] failed to convert content to data")
            return []
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("[NSE] [CHATDB] failed to parse JSON")
                return []
            }
            
            var mutedConversationIds: [String] = []
            
            // Extract community IDs (if any)
            if let communityIds = json["communityIds"] as? [String] {
                mutedConversationIds.append(contentsOf: communityIds)
            }
            
            // Extract master pubkeys and generate one-to-one conversation IDs
            if let masterPubkeys = json["masterPubkeys"] as? [String] {
                for masterPubkey in masterPubkeys {
                    // Generate conversation ID for one-to-one conversation
                    // This matches the Dart logic: generateConversationId(conversationType: ConversationType.oneToOne, ...)
                    let conversationId = generateOneToOneConversationId(
                        receiverPubkey: masterPubkey,
                        currentUserPubkey: currentUserMasterPubkey
                    )
                    mutedConversationIds.append(conversationId)
                }
            }
            
            return mutedConversationIds
            
        } catch {
            NSLog("[NSE] [CHATDB] JSON parsing error: %@", error.localizedDescription)
            return []
        }
    }
    
    /// Generates a one-to-one conversation ID from two pubkeys
    /// This should match the Dart generateConversationId logic
    /// - Parameters:
    ///   - receiverPubkey: The receiver's master pubkey
    ///   - currentUserPubkey: The current user's master pubkey
    /// - Returns: Generated conversation ID
    private func generateOneToOneConversationId(receiverPubkey: String, currentUserPubkey: String) -> String {
        // Sort the pubkeys to ensure consistent conversation ID generation
        // This should match the Dart implementation
        let sortedPubkeys = [receiverPubkey, currentUserPubkey].sorted()
        return sortedPubkeys.joined(separator: "")
    }
}
