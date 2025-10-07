// SPDX-License-Identifier: ice License 1.0

import Foundation
import SQLite3

class IonConnectCacheDatabase: DatabaseManager {
    
    init(keysStorage: KeysStorage) {
        super.init(
            keysStorage: keysStorage,
            logPrefix: "[ION_CACHE]",
            databaseNamePattern: "ion_connect_cache.sqlite"
        )
    }
    
    /// Override to use a fixed database name (not pubkey-based)
    override func openDatabase() -> Bool {
        guard let databasePath = getDatabasePath() else {
            NSLog("[NSE] \(logPrefix) database not found")
            return false
        }
        
        if sqlite3_open(databasePath, &database) != SQLITE_OK {
            NSLog("[NSE] \(logPrefix) sqlite3_open failed: %@", String(cString: sqlite3_errmsg(database)))
            sqlite3_close(database)
            database = nil
            return false
        }
        
        return true
    }
    
    /// Retrieves a cached entity associated with a given event reference.
    /// - Parameter eventReference: The event reference string (cache key).
    /// - Returns: The parsed `IonConnectEntity` of type `T`, or `nil` if not found or invalid.
    func getEntity<T: IonConnectEntity>(for eventReference: String) -> T? {
        guard let eventMessage = getEventMessage(for: eventReference) else {
            NSLog("[NSE] No event message found for \(eventReference)")
            return nil
        }
        
        do {
            guard let entity = try EventParser.parse(eventMessage) as? T else {
                NSLog("[NSE] Parsed entity type mismatch for \(T.self)")
                return nil
            }
            return entity
        } catch {
            NSLog("[NSE] Failed to parse entity from cache: \(error)")
            return nil
        }
    }
    
    /// Retrieves a cached entity associated with a given event reference.
    /// - Parameter eventReference: The event reference string (cache key).
    /// - Returns: The parsed `IonConnectEntity` or `nil` if not found or invalid.
    func getGenericEntity(for eventReference: String) -> IonConnectEntity? {
        guard let eventMessage = getEventMessage(for: eventReference) else {
            NSLog("[NSE] No event message found for \(eventReference)")
            return nil
        }
        
        do {
            return try EventParser.parse(eventMessage)
        } catch {
            NSLog("[NSE] Failed to parse entity from cache: \(error)")
            return nil
        }
    }
        
    /// Gets an EventMessage from the cache by cache key
    /// - Parameter eventReference: The event reference string
    /// - Returns: EventMessage if found, nil otherwise
    private func getEventMessage(for eventReference: String) -> EventMessage? {
        let query = """
            SELECT kind, created_at, master_pubkey, content, tags, sig, id, pubkey
            FROM event_messages_table
            WHERE cache_key = ?
            LIMIT 1
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            NSLog("[NSE] \(logPrefix) Failed to prepare query for event eference: \(eventReference)")
            return nil
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        // Bind the cache key parameter
        sqlite3_bind_text(statement, 1, (eventReference as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            NSLog("[NSE] \(logPrefix) No cached entity found for event eference: \(eventReference)")
            return nil
        }
        
        // Extract columns
        let kind = Int(sqlite3_column_int(statement, 0))
        let createdAt = Int(sqlite3_column_int(statement, 1))
        let masterPubkeyPtr = sqlite3_column_text(statement, 2)
        let contentPtr = sqlite3_column_text(statement, 3)
        let tagsPtr = sqlite3_column_text(statement, 4)
        let sigPtr = sqlite3_column_text(statement, 5)
        let idPtr = sqlite3_column_text(statement, 6)
        let pubkeyPtr = sqlite3_column_text(statement, 7)
        
        guard let masterPubkeyPtr = masterPubkeyPtr,
              let contentPtr = contentPtr,
              let tagsPtr = tagsPtr,
              let idPtr = idPtr,
              let pubkeyPtr = pubkeyPtr else {
            NSLog("[NSE] \(logPrefix) Missing required fields in cached entity")
            return nil
        }
        
        let masterPubkey = String(cString: masterPubkeyPtr)
        let content = String(cString: contentPtr)
        let tagsJson = String(cString: tagsPtr)
        let id = String(cString: idPtr)
        let pubkey = String(cString: pubkeyPtr)
        let sig = sigPtr != nil ? String(cString: sigPtr!) : nil
        
        // Parse tags JSON
        guard let tagsData = tagsJson.data(using: .utf8),
              let tags = try? JSONDecoder().decode([[String]].self, from: tagsData) else {
            NSLog("[NSE] \(logPrefix) Failed to parse tags JSON from cache")
            return nil
        }
        
        return EventMessage(
            id: id,
            pubkey: pubkey,
            createdAt: createdAt,
            kind: kind,
            tags: tags,
            content: content,
            sig: sig
        )
    }
        
    /// Gets the database file path in the app group container
    private func getDatabasePath() -> String? {
        let appGroupIdentifier = keysStorage.storage.appGroupIdentifier
        
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            NSLog("[NSE] \(logPrefix) Failed to get container URL for app group: \(appGroupIdentifier)")
            return nil
        }
        
        let dbPath = containerURL.appendingPathComponent(databaseNamePattern).path
        
        if !fileManager.fileExists(atPath: dbPath) {
            NSLog("[NSE] \(logPrefix) Database file does not exist at: \(dbPath)")
            return nil
        }
        
        return dbPath
    }
}
