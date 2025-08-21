// SPDX-License-Identifier: ice License 1.0

import Foundation

struct RichText {
    let `protocol`: String
    let content: String
    
    static let tagName = "rich_text"
    
    static func fromTag(_ tag: [String]) throws -> RichText {
        guard tag[0] == tagName else {
            throw IncorrectEventTagNameException(actual: tag[0], expected: tagName)
        }
        guard tag.count >= 3 else {
            throw IncorrectEventTagException(tag: tag.description)
        }
        return RichText(protocol: tag[1], content: tag[2])
    }
    
    func toTag() -> [String] {
        return [RichText.tagName, `protocol`, content]
    }
}
