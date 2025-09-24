// SPDX-License-Identifier: ice License 1.0

import Foundation

extension String {
    private static let emojiOnlyRegex: NSRegularExpression? = {
        do {
            // Match Flutter's regex pattern exactly
            return try NSRegularExpression(
                pattern: #"^(?:\p{Emoji}|\p{Emoji_Presentation}|\p{Extended_Pictographic})(?!\d)$"#,
                options: []
            )
        } catch {
            return nil
        }
    }()
    
    var isEmoji: Bool {
        guard !isEmpty else { return false }
        
        if self.allSatisfy({ $0.isNumber }) {
            return false
        }
        
        guard let regex = Self.emojiOnlyRegex else { return false }
        
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}
