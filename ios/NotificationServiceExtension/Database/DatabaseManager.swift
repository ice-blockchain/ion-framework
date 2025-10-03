// SPDX-License-Identifier: ice License 1.0

import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Base class for all database managers to eliminate code duplication
class DatabaseManager {
    let keysStorage: KeysStorage
    var database: OpaquePointer?
    let fileManager = FileManager.default
    let logPrefix: String
    let databaseNamePattern: String
    
    /// Initialize base database manager
    /// - Parameters:
    ///   - keysStorage: KeysStorage storage instance
    ///   - logPrefix: Prefix for log messages (e.g., "[CHATDB]")
    ///   - databaseNamePattern: Pattern for database name (e.g., "chat_database_%@.sqlite")
    init(keysStorage: KeysStorage, logPrefix: String, databaseNamePattern: String) {
        self.keysStorage = keysStorage
        self.logPrefix = logPrefix
        self.databaseNamePattern = databaseNamePattern
    }
    
    // MARK: - Database Connection Management
    
    @discardableResult
    func openDatabase() -> Bool {
        guard let pubkey = keysStorage.getCurrentPubkey() else {
            NSLog("[NSE] \(logPrefix) missing current pubkey")
            return false
        }
        
        guard let databasePath = getDatabasePath(pubkey: pubkey) else {
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
    
    func closeDatabase() {
        if database != nil {
            sqlite3_close(database)
            database = nil
        }
    }
    
    // MARK: - Query Execution
    
    func executeQuery(_ query: String) -> [[String: Any]]? {
        guard database != nil else {
            NSLog("[NSE] \(logPrefix) database not open")
            return nil
        }
        
        var statement: OpaquePointer?
        var results: [[String: Any]] = []
        
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String: Any] = [:]
                let columns = sqlite3_column_count(statement)
                
                for i in 0..<columns {
                    let columnName = String(cString: sqlite3_column_name(statement, i))
                    
                    switch sqlite3_column_type(statement, i) {
                    case SQLITE_INTEGER:
                        row[columnName] = Int64(sqlite3_column_int64(statement, i))
                    case SQLITE_FLOAT:
                        row[columnName] = Double(sqlite3_column_double(statement, i))
                    case SQLITE_TEXT:
                        if let cString = sqlite3_column_text(statement, i) {
                            row[columnName] = String(cString: cString)
                        }
                    case SQLITE_BLOB:
                        if let dataPtr = sqlite3_column_blob(statement, i) {
                            let size = sqlite3_column_bytes(statement, i)
                            row[columnName] = Data(bytes: dataPtr, count: Int(size))
                        }
                    case SQLITE_NULL:
                        row[columnName] = NSNull()
                    default:
                        NSLog("[NSE] \(logPrefix) unknown column type: \(sqlite3_column_type(statement, i))")
                    }
                }
                
                results.append(row)
            }
        } else {
            NSLog("[NSE] \(logPrefix) prepare failed: %@", String(cString: sqlite3_errmsg(database)))
            sqlite3_finalize(statement)
            return nil
        }
        
        sqlite3_finalize(statement)
        return results
    }
    
    // MARK: - Utility Methods
    
    func tableExists(_ name: String) -> Bool {
        guard database != nil else { return false }
        var statement: OpaquePointer?
        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1"
        
        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) != SQLITE_OK {
            return false
        }
        
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, SQLITE_TRANSIENT)
        let exists = sqlite3_step(statement) == SQLITE_ROW
        
        if !exists {
            NSLog("[NSE] \(logPrefix) table missing: %@", name)
        }
        
        return exists
    }
    
    // MARK: - Private Methods
    
    private func getDatabasePath(pubkey: String) -> String? {
        let appGroupIdentifier = keysStorage.storage.appGroupIdentifier
        
        if let sharedContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let databaseName = String(format: databaseNamePattern, pubkey)
            let sharedDatabaseURL = sharedContainerURL.appendingPathComponent(databaseName)
            
            if fileManager.fileExists(atPath: sharedDatabaseURL.path) {
                return sharedDatabaseURL.path
            }
        }
        
        return nil
    }
}
