import Foundation

enum CardFormatting {
    static func digitsOnly(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    static func formatCardNumber(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(19))
        return stride(from: 0, to: digits.count, by: 4).map { index in
            let start = digits.index(digits.startIndex, offsetBy: index)
            let end = digits.index(start, offsetBy: min(4, digits.count - index), limitedBy: digits.endIndex) ?? digits.endIndex
            return String(digits[start..<end])
        }.joined(separator: " ")
    }

    static func formatExpiry(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(4))
        guard digits.count > 2 else { return digits }
        let month = digits.prefix(2)
        let year = digits.suffix(digits.count - 2)
        return "\(month)/\(year)"
    }

    static func normalizeExpiry(_ value: String) -> String {
        formatExpiry(value)
    }

    static func normalizeCardNumber(_ value: String) -> String {
        digitsOnly(value)
    }

    static func normalizeCVV(_ value: String) -> String {
        String(digitsOnly(value).prefix(4))
    }

    static func last4(from number: String) -> String {
        String(number.suffix(4))
    }
}
