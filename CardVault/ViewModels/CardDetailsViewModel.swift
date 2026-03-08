import Foundation
import Combine

@MainActor
final class CardDetailsViewModel: ObservableObject {
    @Published var card: Card
    @Published var isCardNumberRevealed = false
    @Published var isCVVRevealed = false

    private var cardRevealTask: Task<Void, Never>?
    private var cvvRevealTask: Task<Void, Never>?

    init(card: Card) {
        self.card = card
    }

    func updateCard(_ updated: Card) {
        card = updated
    }

    func toggleCardNumber() {
        isCardNumberRevealed.toggle()
        cardRevealTask?.cancel()

        guard isCardNumberRevealed else { return }
        cardRevealTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.isCardNumberRevealed = false
            }
        }
    }

    func toggleCVV() {
        isCVVRevealed.toggle()
        cvvRevealTask?.cancel()

        guard isCVVRevealed else { return }
        cvvRevealTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.isCVVRevealed = false
            }
        }
    }
}
