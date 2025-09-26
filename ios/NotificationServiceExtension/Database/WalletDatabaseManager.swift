// SPDX-License-Identifier: ice License 1.0

import Foundation
import SQLite3

struct FundsRequestDisplayData {
    let amount: String?
    let assetId: String?
}

struct CoinDBInfo {
    let abbreviation: String  // uppercased symbol
    let decimals: Int
}

final class WalletsDatabase: DatabaseManager {
    init(keysStorage: KeysStorage) {
        super.init(
            keysStorage: keysStorage,
            logPrefix: "[WALLETDB]",
            databaseNamePattern: "wallets_database_%@.sqlite"
        )
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
