import Foundation

enum CardRepositoryError: LocalizedError {
    case missingSensitiveData
    case cardNotFound

    var errorDescription: String? {
        switch self {
        case .missingSensitiveData:
            return "Sensitive card data is missing from Keychain."
        case .cardNotFound:
            return "Card not found."
        }
    }
}

protocol CardRepositoryProtocol {
    func fetchCards() async throws -> [Card]
    func addCard(_ input: CardInput) async throws -> Card
    func updateCard(id: UUID, input: CardInput) async throws -> Card
    func deleteCard(id: UUID) async throws
}

actor CardRepository: CardRepositoryProtocol {
    private let keychain: KeychainServicing
    private let metadataStore: CardMetadataStoring

    init(keychain: KeychainServicing, metadataStore: CardMetadataStoring) {
        self.keychain = keychain
        self.metadataStore = metadataStore
    }

    func fetchCards() async throws -> [Card] {
        let metadata = try metadataStore.load().sorted { $0.createdAt > $1.createdAt }
        return try metadata.map(buildCard)
    }

    func addCard(_ input: CardInput) async throws -> Card {
        try CardValidation.validate(input)

        let id = UUID()
        let normalizedCard = CardFormatting.normalizeCardNumber(input.cardNumber)
        let normalizedCVV = CardFormatting.normalizeCVV(input.cvv)

        try storeSensitiveData(id: id, cardNumber: normalizedCard, cvv: normalizedCVV)

        var items = try metadataStore.load()
        let metadata = CardMetadata(
            id: id,
            expiryDate: CardFormatting.normalizeExpiry(input.expiryDate),
            bankName: input.bankName.trimmingCharacters(in: .whitespacesAndNewlines),
            provider: input.provider,
            cardType: input.cardType,
            creditLimit: input.cardType == .credit ? input.creditLimit : nil,
            notes: input.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            last4: CardFormatting.last4(from: normalizedCard),
            createdAt: Date()
        )
        items.append(metadata)
        try metadataStore.save(items)

        return Card(
            id: id,
            cardNumber: normalizedCard,
            expiryDate: metadata.expiryDate,
            cvv: normalizedCVV,
            bankName: metadata.bankName,
            provider: metadata.provider,
            cardType: metadata.cardType,
            creditLimit: metadata.creditLimit,
            notes: metadata.notes,
            createdAt: metadata.createdAt
        )
    }

    func updateCard(id: UUID, input: CardInput) async throws -> Card {
        try CardValidation.validate(input)

        var items = try metadataStore.load()
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw CardRepositoryError.cardNotFound
        }

        let normalizedCard = CardFormatting.normalizeCardNumber(input.cardNumber)
        let normalizedCVV = CardFormatting.normalizeCVV(input.cvv)
        try storeSensitiveData(id: id, cardNumber: normalizedCard, cvv: normalizedCVV)

        items[index].expiryDate = CardFormatting.normalizeExpiry(input.expiryDate)
        items[index].bankName = input.bankName.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].provider = input.provider
        items[index].cardType = input.cardType
        items[index].creditLimit = input.cardType == .credit ? input.creditLimit : nil
        items[index].notes = input.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].last4 = CardFormatting.last4(from: normalizedCard)

        try metadataStore.save(items)

        let item = items[index]
        return Card(
            id: id,
            cardNumber: normalizedCard,
            expiryDate: item.expiryDate,
            cvv: normalizedCVV,
            bankName: item.bankName,
            provider: item.provider,
            cardType: item.cardType,
            creditLimit: item.creditLimit,
            notes: item.notes,
            createdAt: item.createdAt
        )
    }

    func deleteCard(id: UUID) async throws {
        var items = try metadataStore.load()
        items.removeAll { $0.id == id }
        try metadataStore.save(items)

        try keychain.delete(cardNumberKey(for: id))
        try keychain.delete(cvvKey(for: id))
    }

    private func buildCard(from metadata: CardMetadata) throws -> Card {
        guard let numberData = try keychain.read(cardNumberKey(for: metadata.id)),
              let cvvData = try keychain.read(cvvKey(for: metadata.id)),
              let cardNumber = String(data: numberData, encoding: .utf8),
              let cvv = String(data: cvvData, encoding: .utf8) else {
            throw CardRepositoryError.missingSensitiveData
        }

        return Card(
            id: metadata.id,
            cardNumber: cardNumber,
            expiryDate: metadata.expiryDate,
            cvv: cvv,
            bankName: metadata.bankName,
            provider: metadata.provider,
            cardType: metadata.cardType,
            creditLimit: metadata.creditLimit,
            notes: metadata.notes,
            createdAt: metadata.createdAt
        )
    }

    private func storeSensitiveData(id: UUID, cardNumber: String, cvv: String) throws {
        try keychain.save(Data(cardNumber.utf8), for: cardNumberKey(for: id))
        try keychain.save(Data(cvv.utf8), for: cvvKey(for: id))
    }

    private func cardNumberKey(for id: UUID) -> String {
        "cardvault.card.number.\(id.uuidString)"
    }

    private func cvvKey(for id: UUID) -> String {
        "cardvault.card.cvv.\(id.uuidString)"
    }
}
