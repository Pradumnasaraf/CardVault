import Foundation
import Combine

@MainActor
final class CardListViewModel: ObservableObject {
    @Published private(set) var cards: [Card] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    let repository: CardRepositoryProtocol

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

    func removeCard(id: UUID) {
        cards.removeAll { $0.id == id }
    }

    func upsert(_ card: Card) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        } else {
            cards.insert(card, at: 0)
        }
    }
}
