// SPDX-License-Identifier: ice License 1.0

import Foundation
import UIKit

enum CounterCategory: String, CaseIterable {
    case inapp = "app_badge_count"
    case chat = "app_badge_chat_count"
    
    var key: String {
        return self.rawValue
    }
}

class AppBadgeCounterService {
    static private let unreadConversationsKey = "unread_conversations"
    
    private let storage: SharedStorage
    
    init(storage: SharedStorage) {
        self.storage = storage
    }
    
    // MARK: - Badge Count Methods
    
    func setBadgeCount(_ count: Int, category: CounterCategory) {
        storage.setInt(count, forKey: category.key)
    }
    
    func getTotalBadgeCount() -> Int {
        let totalCount = CounterCategory.allCases.reduce(0) { sum, category in
            return sum + storage.getInt(forKey: category.key)
        }
        
        return totalCount
    }
    
    // MARK: - Conversation Methods
    
    func getUnreadConversations() -> [String]? {
        storage.getStringArray(forKey: AppBadgeCounterService.unreadConversationsKey)
    }
    
    func setUnreadConversation(_ id: String) {
        var unreadConversations = getUnreadConversations() ?? []
        if !unreadConversations.contains(id) {
            unreadConversations.append(id)
            storage.setStringArray(unreadConversations, forKey: AppBadgeCounterService.unreadConversationsKey)
        }
    }
    
    func isUnreadConversation(_ id: String) -> Bool {
        return getUnreadConversations()?.contains(id) ?? false
    }
    
    func getBadgeCount(for category: CounterCategory) -> Int {
        return storage.getInt(forKey: category.key)
    }
}
