import Foundation
import Combine

@MainActor
final class CardDetailsViewModel: ObservableObject {
    @Published var card: Card

    init(card: Card) {
        self.card = card
    }

    func updateCard(_ updated: Card) {
        card = updated
    }
}
