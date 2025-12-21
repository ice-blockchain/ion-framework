// SPDX-License-Identifier: ice License 1.0

final class IonConnectUriProtocolService {
    private static let ionPrefix = "ion:"
    private static let nostrPrefix = "nostr:"

    func decode(_ uri: String) -> String? {
        for prefix in [Self.ionPrefix, Self.nostrPrefix] {
            if uri.hasPrefix(prefix) {
                return String(uri.dropFirst(prefix.count))
            }
        }
        return nil
    }

    func encode(_ content: String) -> String {
        return Self.ionPrefix + content
    }
}

