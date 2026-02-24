// SPDX-License-Identifier: ice License 1.0

import Foundation

enum PriceFormatter {
    /// Formats a price with subscript notation for very small values.
    /// Examples:
    /// 0.1 -> $0.10
    /// 0.12 -> $0.12
    /// 0.123 -> $0.123
    /// 0.001 -> $0.001
    /// 0.0001 -> $0.0₃1
    /// 0.00001 -> $0.0₄1
    static func formatPriceWithSubscript(_ price: Double, symbol: String = "$") -> String {
        let absPrice = abs(price)
        
        if absPrice >= 0.01 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = symbol
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: NSNumber(value: price)) ?? "\(symbol)0.00"
        }
        
        if absPrice >= 0.001 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = symbol
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 3
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: NSNumber(value: price)) ?? "\(symbol)0.000"
        }
        
        if absPrice == 0 {
            return "\(symbol)0.00"
        }
        
        // For very small values, use subscript notation
        let subscriptResult = formatSubscriptNotation(price, symbol: symbol)
        if subscriptResult.isEmpty {
            // Fallback if subscript formatting fails
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = symbol
            formatter.minimumFractionDigits = 4
            formatter.maximumFractionDigits = 4
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: NSNumber(value: price)) ?? "\(symbol)0.0000"
        }
        return subscriptResult
    }
    
    /// Formats a value using subscript notation for very small numbers.
    /// Returns a string like "$0.0₂25" for very small values.
    private static func formatSubscriptNotation(_ value: Double, symbol: String = "") -> String {
        let absValue = abs(value)
        
        // Use scientific notation to analyze the value
        let scientificString = String(format: "%.12e", absValue)
        
        // Parse the scientific notation: e.g., "1.234567e-05"
        guard let regex = try? NSRegularExpression(pattern: #"^(\d(?:\.\d+)?)e([+-]\d+)$"#),
              let match = regex.firstMatch(in: scientificString, range: NSRange(scientificString.startIndex..., in: scientificString)) else {
            return ""
        }
        
        guard let mantissaRange = Range(match.range(at: 1), in: scientificString),
              let exponentRange = Range(match.range(at: 2), in: scientificString) else {
            return ""
        }
        
        let mantissaStr = String(scientificString[mantissaRange])
        let exponentStr = String(scientificString[exponentRange])
        
        guard let exponent = Int(exponentStr) else {
            return ""
        }
        
        let absExponent = abs(exponent)
        let zeroCount = absExponent - 1
        
        // Get digits from mantissa (remove decimal point)
        let digits = mantissaStr.replacingOccurrences(of: ".", with: "")
        
        // Keep at most 2 significant digits for the trailing part
        var trailing = String(digits.prefix(2))
        // Remove trailing zeros
        trailing = trailing.replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
        if trailing.isEmpty {
            trailing = "0"
        }
        
        let sign = value < 0 ? "-" : ""
        return "\(sign)\(symbol)0.0\(toSubscript(zeroCount))\(trailing)"
    }
    
    /// Converts a number to its subscript Unicode representation
    private static func toSubscript(_ number: Int) -> String {
        let subscriptDigits = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
        return String(number).map { char in
            if let digit = Int(String(char)) {
                return subscriptDigits[digit]
            }
            return String(char)
        }.joined()
    }
}
