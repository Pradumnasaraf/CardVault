import Foundation
import Combine

@MainActor
final class CardListViewModel: ObservableObject {
    @Published private(set) var cards: [Card] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var cardPendingDeletion: Card?

    private let repository: CardRepositoryProtocol

    init(repository: CardRepositoryProtocol) {
        self.repository = repository
    }

    func loadCards() async {
        isLoading = true
        defer { isLoading = false }

        do {
            cards = try await repository.fetchCards()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestDelete(_ card: Card) {
        cardPendingDeletion = card
    }

    func confirmDelete() async {
        guard let card = cardPendingDeletion else { return }
        cardPendingDeletion = nil

        do {
            try await repository.deleteCard(id: card.id)
            cards.removeAll { $0.id == card.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelDelete() {
        cardPendingDeletion = nil
    }

    func upsert(_ card: Card) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        } else {
            cards.insert(card, at: 0)
        }
    }
}
