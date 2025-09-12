// SPDX-License-Identifier: ice License 1.0

import Foundation

enum IonConnectProtocolIdentifierType: String, CaseIterable {
    case nprofile
    case nevent
    case naddr

    var name: String { rawValue }
}

struct ShareableIdentifier {
    let prefix: IonConnectProtocolIdentifierType
    let special: String
    let relays: [String]
    let author: String?
    let kind: Int?
}
