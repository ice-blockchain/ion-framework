// SPDX-License-Identifier: ice License 1.0

import Foundation

enum DelegationStatus: String, CaseIterable {
    case active
    case inactive
    case revoked
}

struct UserDelegationEntity: IonConnectEntity {
    let id: String
    let pubkey: String
    let masterPubkey: String
    let signature: String
    let createdAt: Int
    let data: UserDelegationData

    static let kind = 10100

    static func fromEventMessage(_ eventMessage: EventMessage) throws
        -> UserDelegationEntity
    {
        if eventMessage.kind != kind {
            throw IncorrectEventKindException(eventMessage, kind: kind)
        }

        return UserDelegationEntity(
            id: eventMessage.id,
            pubkey: eventMessage.pubkey,
            masterPubkey: eventMessage.pubkey,
            signature: eventMessage.sig ?? "",
            createdAt: eventMessage.createdAt,
            data: UserDelegationData.fromEventMessage(eventMessage)
        )
    }
}

struct UserDelegationData {
    let delegates: [UserDelegate]

    static func fromEventMessage(_ eventMessage: EventMessage)
        -> UserDelegationData
    {
        let delegates = eventMessage.tags
            .filter { tag in tag.count > 0 && tag[0] == "p" }
            .compactMap { UserDelegate.fromTag($0) }

        return UserDelegationData(delegates: delegates)
    }

    func validate(_ message: EventMessage) -> Bool {
        var currentDelegates: [String: UserDelegate] = [:]

        for delegate in delegates {
            if let existingDelegate = currentDelegates[delegate.pubkey],
                existingDelegate.status == .inactive
                    || existingDelegate.status == .revoked
            {
                continue
            }
            currentDelegates[delegate.pubkey] = delegate
        }

        if let delegate = currentDelegates[message.pubkey] {
            let isActive = delegate.status == .active
            let hasValidKind =
                delegate.kinds == nil || delegate.kinds!.contains(message.kind)

            return isActive && hasValidKind
        }

        return false
    }
}

struct UserDelegate {
    let pubkey: String
    let relay: String
    let status: DelegationStatus
    let time: Date
    let kinds: [Int]?

    static func fromTag(_ tag: [String]) -> UserDelegate {
        let pubkey = tag[1]
        let relay = tag[2]
        let attestationString = tag[3]

        let attestation = attestationString.split(separator: ":")
        let statusName = attestation[0]
        let timestamp = attestation[1]
        let kindsString = attestation.count > 2 ? attestation[2] : nil

        let status: DelegationStatus
        do {
            guard
                let delegationStatus = DelegationStatus(
                    rawValue: String(statusName)
                )
            else {
                throw IncorrectEventTagNameException(
                    actual: String(statusName),
                    expected: DelegationStatus.allCases.map { $0.rawValue }
                        .joined(separator: ",")
                )
            }
            status = delegationStatus
        } catch {
            NSLog("[NSE] Error parsing delegation status: \(error)")
            status = .inactive  // Default to inactive if there's an error
        }
        let time = Date(
            timeIntervalSince1970: TimeInterval(Int(timestamp)!) / 1000.0
        )
        let kinds = kindsString?.split(separator: ",").compactMap { Int($0) }

        return UserDelegate(
            pubkey: pubkey,
            relay: relay,
            status: status,
            time: time,
            kinds: kinds
        )
    }

    func toTag() -> [String] {
        var attestationParts = [
            status.rawValue, String(Int(time.timeIntervalSince1970)),
        ]

        if let kinds = kinds, !kinds.isEmpty {
            attestationParts.append(
                kinds.map { String($0) }.joined(separator: ",")
            )
        }

        return ["p", pubkey, relay, attestationParts.joined(separator: ":")]
    }
}
