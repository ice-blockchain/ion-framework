// SPDX-License-Identifier: ice License 1.0

import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct FundsRequestDisplayData {
    let amount: String?
    let assetId: String?
}

struct CoinDBInfo {
    let abbreviation: String  // uppercased symbol
    let decimals: Int
}

final class WalletsDatabaseManager {
    private let storage: SharedStorageService
    private var database: OpaquePointer?
    private let fileManager = FileManager.default

    init(storage: SharedStorageService) {
        self.storage = storage
    }

    @discardableResult
    func openDatabase() -> Bool {
        guard let pubkey = storage.getCurrentPubkey() else {
            NSLog("[WALLETDB] missing current pubkey")
            return false
        }
        guard let databasePath = getDatabasePath(pubkey: pubkey) else {
            NSLog("[WALLETDB] wallets db not found")
            return false
        }
        if sqlite3_open(databasePath, &database) != SQLITE_OK {
            NSLog("[WALLETDB] sqlite3_open failed: %@", String(cString: sqlite3_errmsg(database)))
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

    private func getDatabasePath(pubkey: String) -> String? {
        let appGroupIdentifier = storage.appGroupIdentifier

        if let sharedContainerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let databaseName = "wallets_database_\(pubkey).sqlite"
            let sharedDatabaseURL = sharedContainerURL.appendingPathComponent(databaseName)

            if fileManager.fileExists(atPath: sharedDatabaseURL.path) {
                return sharedDatabaseURL.path
            }
        }

        return nil
    }

    private func executeQuery(_ query: String) -> [[String: Any]]? {
        guard database != nil else { return nil }
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
                        break
                    }
                }
                results.append(row)
            }
        } else {
            NSLog("[WALLETDB] prepare failed: %@", String(cString: sqlite3_errmsg(database)))
            sqlite3_finalize(statement)
            return nil
        }
        sqlite3_finalize(statement)
        return results
    }

    private func tableExists(_ name: String) -> Bool {
        guard database != nil else { return false }
        var statement: OpaquePointer?
        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1"
        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) != SQLITE_OK { return false }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, SQLITE_TRANSIENT)
        let exists = sqlite3_step(statement) == SQLITE_ROW
        if !exists {
            NSLog("[WALLETDB] table missing: %@", name)
        }
        return exists
    }

    /// Fetch `asset_id` and `amount` for a funds request by `event_id`
    func getFundsRequestDisplayData(eventId: String) -> FundsRequestDisplayData? {
        guard tableExists("funds_requests_table") else { return nil }
        let safeId = eventId.replacingOccurrences(of: "'", with: "''")
        let query = """
        SELECT asset_id, amount
        FROM funds_requests_table
        WHERE event_id = '\(safeId)' COLLATE NOCASE
        LIMIT 1
        """
        guard let rows = executeQuery(query), let row = rows.first else {
            NSLog("[WALLETDB] funds request not found for eventId=%@", eventId)
            return nil
        }
        let assetId = row["asset_id"] as? String
        let amount = row["amount"] as? String
        return FundsRequestDisplayData(amount: amount, assetId: assetId)
    }

    /// Fetch the coin abbreviation (uppercase symbol) and decimals by `assetId` from `coins_table`
    func getCoinData(assetId: String) -> CoinDBInfo? {
        guard tableExists("coins_table") else { return nil }
        let safeId = assetId.replacingOccurrences(of: "'", with: "''")
        let query = """
        SELECT symbol, decimals
        FROM coins_table
        WHERE id = '\(safeId)' COLLATE NOCASE
        LIMIT 1
        """
        guard let rows = executeQuery(query), let row = rows.first else {
            NSLog("[WALLETDB] coin not found for assetId=%@", assetId)
            return nil
        }
        guard let symbol = row["symbol"] as? String, !symbol.isEmpty else {
            NSLog("[WALLETDB] coin symbol missing for assetId=%@", assetId)
            return nil
        }
        var decimalsValue: Int?
        if let d = row["decimals"] as? Int { decimalsValue = d }
        if let d = row["decimals"] as? Int64 { decimalsValue = Int(d) }
        guard let decimals = decimalsValue else {
            NSLog("[WALLETDB] coin decimals missing for assetId=%@", assetId)
            return nil
        }
        return CoinDBInfo(abbreviation: symbol.uppercased(), decimals: decimals)
    }
}