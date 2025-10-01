// SPDX-License-Identifier: ice License 0.1

import Foundation

struct ReplaceableEventIdentifier {
    let value: String
    
    static let tagName = "d"
    
    static func fromTag(_ tag: [String]) -> ReplaceableEventIdentifier? {
        guard tag.count >= 2 && tag[0] == tagName else {
            return nil
        }
        
        return ReplaceableEventIdentifier(value: tag[1])
    }
    
    func toTag() -> [String] {
        return [ReplaceableEventIdentifier.tagName, value]
    }
}
