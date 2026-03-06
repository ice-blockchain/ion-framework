// SPDX-License-Identifier: ice License 1.0

import Foundation

enum TokenInput: String {
    case priceChange
    case trending
    case inspectTokenBuyingActivity

    static let tagName = "i"

    static func fromTag(_ tag: [String]) throws -> TokenInput {
        guard tag.count >= 2, tag[0] == tagName else {
            throw IncorrectEventTagException(tag: tag.description)
        }
        guard let input = TokenInput(rawValue: tag[1]) else {
            throw IncorrectEventTagException(tag: tag.description)
        }
        return input
    }
}
