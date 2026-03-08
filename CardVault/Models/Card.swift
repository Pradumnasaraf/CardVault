import Foundation

enum CardProvider: String, Codable, CaseIterable, Identifiable {
    case visa = "Visa"
    case masterCard = "MasterCard"
    case americanExpress = "American Express"
    case discover = "Discover"
    case ruPay = "RuPay"
    case other = "Other"

    var id: String { rawValue }

    var logoAssetName: String? {
        switch self {
        case .visa:
            return "ProviderVisa"
        case .masterCard:
            return "ProviderMastercard"
        case .americanExpress:
            return "ProviderAmex"
        case .discover:
            return "ProviderDiscover"
        case .ruPay:
            return "ProviderRupay"
        case .other:
            return nil
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
    var cardholderName: String
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
    var cardholderName: String
    var bankName: String
    var provider: CardProvider
    var cardType: CardType
    var creditLimit: Decimal?
    var notes: String
    var last4: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case expiryDate
        case cardholderName
        case bankName
        case provider
        case cardType
        case creditLimit
        case notes
        case last4
        case createdAt
    }

    init(
        id: UUID,
        expiryDate: String,
        cardholderName: String,
        bankName: String,
        provider: CardProvider,
        cardType: CardType,
        creditLimit: Decimal?,
        notes: String,
        last4: String,
        createdAt: Date
    ) {
        self.id = id
        self.expiryDate = expiryDate
        self.cardholderName = cardholderName
        self.bankName = bankName
        self.provider = provider
        self.cardType = cardType
        self.creditLimit = creditLimit
        self.notes = notes
        self.last4 = last4
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        expiryDate = try container.decode(String.self, forKey: .expiryDate)
        cardholderName = try container.decodeIfPresent(String.self, forKey: .cardholderName) ?? ""
        bankName = try container.decode(String.self, forKey: .bankName)
        provider = try container.decode(CardProvider.self, forKey: .provider)
        cardType = try container.decode(CardType.self, forKey: .cardType)
        creditLimit = try container.decodeIfPresent(Decimal.self, forKey: .creditLimit)
        notes = try container.decode(String.self, forKey: .notes)
        last4 = try container.decode(String.self, forKey: .last4)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct SensitiveCardPayload: Equatable {
    var cardNumber: String
    var cvv: String
}

struct CardInput: Equatable {
    var cardNumber: String
    var expiryDate: String
    var cvv: String
    var cardholderName: String
    var bankName: String
    var provider: CardProvider
    var cardType: CardType
    var creditLimit: Decimal?
    var notes: String
}
