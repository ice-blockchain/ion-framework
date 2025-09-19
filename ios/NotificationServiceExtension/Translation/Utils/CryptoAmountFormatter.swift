// SPDX-License-Identifier: ice License 1.0

import Foundation
import Darwin

public enum CryptoAmountFormatter {
    public static func parse(_ input: String, decimals: Int) -> Double {
        if let parsed = Double(input) {
            return parsed / pow(10.0, Double(decimals))
        } else {
            NSLog("[CryptoAmountFormatter] Failed to parse coins amount with `%@` value.", input)
            return 0
        }
    }

    public static func format(_ value: Double, currency: String? = nil) -> String {
        let million = 1_000_000.0
        let billion = 1_000_000_000.0
        let trillion = 1_000_000_000_000.0

        let formatted: String
        switch value {
        case 0:
            formatted = numberString(value, max: 2, min: 2)
        case let v where v >= trillion:
            formatted = abbreviate(value: v, scale: trillion, suffix: "T")
        case let v where v >= billion:
            formatted = abbreviate(value: v, scale: billion, suffix: "B")
        case let v where v >= million:
            formatted = abbreviate(value: v, scale: million, suffix: "M")
        case let v where v >= 10:
            formatted = numberString(v, max: 2, min: 2)
        case let v where v >= 1:
            formatted = smartTruncate(v, max: 6, min: 2)
        case let v where v < 1e-6:
            formatted = verySmallNumber(v)
        default:
            formatted = smartTruncate(value, max: 6, min: 2)
        }
        if let currency = currency { return "\(formatted) \(currency)" }
        return formatted
    }

    static func abbreviate(value: Double, scale: Double, suffix: String) -> String {
        let scaled = value / scale
        let parts = String(scaled).split(separator: ".", omittingEmptySubsequences: false)
        let integer = String(parts.first ?? "0")
        if parts.count == 1 { return integer + suffix }
        var decimal = String(parts[1])
        if decimal.count > 3 { decimal = String(decimal.prefix(3)) }
        decimal = decimal.replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        return decimal.isEmpty ? integer + suffix : integer + "." + decimal + suffix
    }

    static func smartTruncate(_ value: Double, max: Int, min: Int) -> String {
        var parts = String(value).split(separator: ".", omittingEmptySubsequences: false)
        let integer = String(parts.first ?? "0")
        var decimal = parts.count > 1 ? String(parts[1]) : ""
        if decimal.count > max { decimal = String(decimal.prefix(max)) }
        while decimal.count < min { decimal.append("0") }
        while decimal.count > min && decimal.hasSuffix("0") { decimal.removeLast() }
        let reconstructed = Double(integer + "." + decimal) ?? value
        return numberString(reconstructed, max: max, min: min)
    }

    static func verySmallNumber(_ value: Double) -> String {
        let s = String(format: "%.20f", value).replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
        guard let dot = s.firstIndex(of: ".") else { return numberString(value, max: 2, min: 2) }
        let decimals = s[s.index(after: dot)..<s.endIndex]
        var zeros = 0
        for ch in decimals {
            if ch == "0" { zeros += 1 } else { return "0.0(\(zeros))\(ch)" }
        }
        return numberString(0, max: 2, min: 2)
    }

    static func numberString(_ value: Double, max: Int, min: Int) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.maximumFractionDigits = max
        f.minimumFractionDigits = min
        return f.string(from: NSNumber(value: value)) ?? String(value)
    }
}