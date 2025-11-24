// SPDX-License-Identifier: ice License 1.0

import Foundation

protocol IonConnectEntity {
    var id: String { get }
    var pubkey: String { get }
    var masterPubkey: String { get }
    var signature: String { get }
    var createdAt: Int { get }
    func toEventReference() -> EventReference
}

extension IonConnectEntity {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Default implementation for immutable entities
    func toEventReference() -> EventReference {
        return ImmutableEventReference(id: id, pubkey: pubkey, kind: 0, masterPubkey: masterPubkey)
    }
}
