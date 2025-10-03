// SPDX-License-Identifier: ice License 0.1

import Foundation

enum RelatedEventMarker: String {
    case reply
    case root
    case mention
    
    static func fromValue(_ value: String?) -> RelatedEventMarker? {
        guard let value = value else { return nil }
        return RelatedEventMarker(rawValue: value)
    }
}
