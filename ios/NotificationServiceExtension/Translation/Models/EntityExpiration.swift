// SPDX-License-Identifier: ice License 0.1

import Foundation

struct EntityExpiration {
    let value: Int
    
    static let tagName = "expiration"
    
    static func fromTag(_ tag: [String]) -> EntityExpiration? {
        guard tag.count >= 2 && tag[0] == tagName else {
            return nil
        }
        
        guard let value = Int(tag[1]) else {
            return nil
        }
        
        return EntityExpiration(value: value)
    }
    
    func toTag() -> [String] {
        return [EntityExpiration.tagName, String(value)]
    }
}
