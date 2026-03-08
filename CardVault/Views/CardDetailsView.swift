import SwiftUI

struct CardDetailsView: View {
    let repository: CardRepositoryProtocol
    let onCardUpdated: (Card) -> Void

    @StateObject private var viewModel: CardDetailsViewModel
    @State private var showingEdit = false

    init(initialCard: Card, repository: CardRepositoryProtocol, onCardUpdated: @escaping (Card) -> Void) {
        self.repository = repository
        self.onCardUpdated = onCardUpdated
        _viewModel = StateObject(wrappedValue: CardDetailsViewModel(card: initialCard))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PaymentCardView(card: viewModel.card, revealNumber: viewModel.isCardNumberRevealed)
                    .frame(height: 230)
                    .padding(.horizontal)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    DetailInfoRow(
                        title: "Card Number",
                        value: viewModel.isCardNumberRevealed ? CardFormatting.formatCardNumber(viewModel.card.cardNumber) : viewModel.card.maskedNumber,
                        isSensitive: true,
                        actionIcon: viewModel.isCardNumberRevealed ? "eye.slash" : "eye"
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleCardNumber()
                        }
                    }

                    DetailInfoRow(
                        title: "CVV",
                        value: viewModel.isCVVRevealed ? viewModel.card.cvv : "***",
                        isSensitive: true,
                        actionIcon: viewModel.isCVVRevealed ? "eye.slash" : "eye"
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleCVV()
                        }
                    }

                    DetailInfoRow(title: "Expiry Date", value: viewModel.card.expiryDate)
                    DetailInfoRow(title: "Bank Name", value: viewModel.card.bankName)
                    DetailInfoRow(title: "Provider", value: viewModel.card.provider.rawValue)
                    DetailInfoRow(title: "Card Type", value: viewModel.card.cardType.rawValue)

                    if let creditLimit = viewModel.card.creditLimit {
                        DetailInfoRow(
                            title: "Credit Limit",
                            value: NumberFormatter.currency.string(from: NSDecimalNumber(decimal: creditLimit)) ?? "\(creditLimit)"
                        )
                    }

                    DetailInfoRow(
                        title: "Notes",
                        value: viewModel.card.notes.isEmpty ? "No notes added" : viewModel.card.notes
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 18)
        }
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditCardView(repository: repository, existingCard: viewModel.card) { updated in
                viewModel.updateCard(updated)
                onCardUpdated(updated)
            }
        }
    }
}

private extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
