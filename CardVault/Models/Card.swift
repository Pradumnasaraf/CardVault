import Foundation

enum CardProvider: String, Codable, CaseIterable, Identifiable {
    case visa = "Visa"
    case masterCard = "MasterCard"
    case americanExpress = "American Express"
    case discover = "Discover"
    case other = "Other"

    var id: String { rawValue }

    var logoSymbolName: String {
        switch self {
        case .visa:
            return "v.circle.fill"
        case .masterCard:
            return "circle.grid.2x2.fill"
        case .americanExpress:
            return "a.circle.fill"
        case .discover:
            return "d.circle.fill"
        case .other:
            return "creditcard.fill"
        }
    }
}

enum CardType: String, Codable, CaseIterable, Identifiable {
    case debit = "Debit Card"
    case credit = "Credit Card"

    var id: String { rawValue }
}

struct Card: Identifiable, Equatable {
    let id: UUID
    var cardNumber: String
    var expiryDate: String
    var cvv: String
    var bankName: String
    var provider: CardProvider
    var cardType: CardType
    var creditLimit: Decimal?
    var notes: String
    let createdAt: Date

    var last4: String {
        String(cardNumber.suffix(4))
    }

    var maskedNumber: String {
        "**** **** **** \(last4)"
    }
}

struct CardMetadata: Identifiable, Codable, Equatable {
    let id: UUID
    var expiryDate: String
    var bankName: String
    var provider: CardProvider
    var cardType: CardType
    var creditLimit: Decimal?
    var notes: String
    var last4: String
    let createdAt: Date
}

struct SensitiveCardPayload: Equatable {
    var cardNumber: String
    var cvv: String
}

struct CardInput: Equatable {
    var cardNumber: String
    var expiryDate: String
    var cvv: String
    var bankName: String
    var provider: CardProvider
    var cardType: CardType
    var creditLimit: Decimal?
    var notes: String
}
