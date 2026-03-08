import Foundation

enum CardValidationError: LocalizedError {
    case invalidCardNumber
    case invalidExpiry
    case invalidCVV
    case missingCardholderName
    case missingBankName
    case invalidCreditLimit

    var errorDescription: String? {
        switch self {
        case .invalidCardNumber:
            return "Enter a valid card number."
        case .invalidExpiry:
            return "Enter a valid expiry date in MM/YY format."
        case .invalidCVV:
            return "Enter a valid CVV."
        case .missingCardholderName:
            return "Cardholder name is required."
        case .missingBankName:
            return "Bank name is required."
        case .invalidCreditLimit:
            return "Enter a valid credit limit amount."
        }
    }
}

enum CardValidation {
    static func validate(_ input: CardInput) throws {
        let normalizedCard = CardFormatting.normalizeCardNumber(input.cardNumber)
        guard (13...19).contains(normalizedCard.count), passesLuhn(normalizedCard) else {
            throw CardValidationError.invalidCardNumber
        }

        guard isValidExpiry(input.expiryDate) else {
            throw CardValidationError.invalidExpiry
        }

        let normalizedCVV = CardFormatting.normalizeCVV(input.cvv)
        guard (3...4).contains(normalizedCVV.count) else {
            throw CardValidationError.invalidCVV
        }

        guard !input.cardholderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CardValidationError.missingCardholderName
        }

        guard !input.bankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CardValidationError.missingBankName
        }

        if input.cardType == .credit, let limit = input.creditLimit {
            guard limit > 0 else {
                throw CardValidationError.invalidCreditLimit
            }
        }
    }

    static func isValidExpiry(_ value: String) -> Bool {
        let components = value.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]),
              (1...12).contains(month),
              components[1].count == 2 else {
            return false
        }

        var dateComponents = DateComponents()
        dateComponents.year = 2000 + year
        dateComponents.month = month
        dateComponents.day = 1

        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: dateComponents),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return false
        }

        return monthEnd >= calendar.startOfDay(for: Date())
    }

    static func passesLuhn(_ digits: String) -> Bool {
        var sum = 0
        let reversed = digits.reversed().map { Int(String($0)) ?? 0 }
        for (index, digit) in reversed.enumerated() {
            if index.isMultiple(of: 2) {
                sum += digit
            } else {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            }
        }
        return sum % 10 == 0
    }
}
