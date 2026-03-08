import Foundation
import Combine

@MainActor
final class AddEditCardViewModel: ObservableObject {
    @Published var cardNumber: String = "" {
        didSet {
            let formatted = CardFormatting.formatCardNumber(cardNumber)
            if formatted != cardNumber {
                cardNumber = formatted
            }
        }
    }

    @Published private(set) var expiryDate: String = ""
    @Published var expiryMonth: Int {
        didSet { syncExpiryDate() }
    }
    @Published var expiryYear: Int {
        didSet { syncExpiryDate() }
    }

    @Published var cvv: String = "" {
        didSet {
            let normalized = CardFormatting.normalizeCVV(cvv)
            if normalized != cvv {
                cvv = normalized
            }
        }
    }

    @Published var cardholderName: String = ""
    @Published var bankName: String = ""
    @Published var provider: CardProvider = .visa
    @Published var cardType: CardType = .debit {
        didSet {
            if cardType == .debit {
                creditLimitText = ""
            }
        }
    }
    @Published var creditLimitText: String = ""
    @Published var notes: String = ""

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    var title: String { editingCardID == nil ? "Add Card" : "Edit Card" }
    var actionTitle: String { editingCardID == nil ? "Save Card" : "Update Card" }
    let availableExpiryMonths = Array(1...12)
    let availableExpiryYears: [Int]

    private let repository: CardRepositoryProtocol
    private let editingCardID: UUID?

    init(repository: CardRepositoryProtocol, existingCard: Card? = nil) {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        let parsedExpiry = existingCard.flatMap { Self.parseExpiry($0.expiryDate) }
        let initialMonth = parsedExpiry?.month ?? currentMonth
        let initialYear = parsedExpiry?.year ?? currentYear
        let minYear = min(currentYear, initialYear)
        let maxYear = max(currentYear + 25, initialYear)

        self.availableExpiryYears = Array(minYear...maxYear)
        self.expiryMonth = initialMonth
        self.expiryYear = initialYear
        self.repository = repository
        self.editingCardID = existingCard?.id

        if let card = existingCard {
            cardNumber = CardFormatting.formatCardNumber(card.cardNumber)
            cvv = card.cvv
            cardholderName = card.cardholderName
            bankName = card.bankName
            provider = card.provider
            cardType = card.cardType
            if let limit = card.creditLimit {
                creditLimitText = NSDecimalNumber(decimal: limit).stringValue
            }
            notes = card.notes
        }

        syncExpiryDate()
    }

    func save() async -> Card? {
        guard !isSaving else { return nil }

        isSaving = true
        defer { isSaving = false }

        do {
            let input = try buildInput()
            let card: Card

            if let id = editingCardID {
                card = try await repository.updateCard(id: id, input: input)
            } else {
                card = try await repository.addCard(input)
            }

            errorMessage = nil
            return card
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func buildInput() throws -> CardInput {
        let limit: Decimal?
        if cardType == .credit {
            if creditLimitText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                limit = nil
            } else if let decimal = Decimal(string: creditLimitText), decimal > 0 {
                limit = decimal
            } else {
                throw CardValidationError.invalidCreditLimit
            }
        } else {
            limit = nil
        }

        return CardInput(
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            cvv: cvv,
            cardholderName: cardholderName,
            bankName: bankName,
            provider: provider,
            cardType: cardType,
            creditLimit: limit,
            notes: notes
        )
    }

    private func syncExpiryDate() {
        expiryDate = String(format: "%02d/%02d", expiryMonth, expiryYear % 100)
    }

    private static func parseExpiry(_ value: String) -> (month: Int, year: Int)? {
        let components = value.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let shortYear = Int(components[1]),
              (1...12).contains(month) else {
            return nil
        }

        return (month, 2000 + shortYear)
    }
}
