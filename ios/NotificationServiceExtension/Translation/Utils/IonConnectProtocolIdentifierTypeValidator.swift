// SPDX-License-Identifier: ice License 1.0

import Foundation

class IonConnectProtocolIdentifierTypeValidator {
    static func isProfileIdentifier(_ content: String) -> Bool {
        return content.hasPrefix("nostr:nprofile") || content.hasPrefix("ion:nprofile") || content.hasPrefix("npub")
    }
    
    static func isEventIdentifier(_ content: String) -> Bool {
        return content.hasPrefix("nostr:note") || content.hasPrefix("ion:note") || content.hasPrefix("note")
    }
}
