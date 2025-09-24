// SPDX-License-Identifier: ice License 1.0

import Foundation

extension String {
    var isEmoji: Bool {
        guard !isEmpty else { return false }
        
        if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self)) {
            return false
        }
        
        return unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji || 
            scalar.properties.isEmojiPresentation
        }
    }
}
