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
                PaymentCardView(card: viewModel.card, revealSensitive: true)
                    .frame(height: 230)
                    .padding(.horizontal)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Card Features & Info")
                                .font(.headline)
                            Spacer()
                            Button("Edit") {
                                showingEdit = true
                            }
                            .font(.subheadline.weight(.semibold))
                        }

                        Text(viewModel.card.notes.isEmpty ? "No additional card features or notes added." : viewModel.card.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.regularMaterial)
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 18)
        }
        .navigationTitle("Card Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            AddEditCardView(repository: repository, existingCard: viewModel.card) { updated in
                viewModel.updateCard(updated)
                onCardUpdated(updated)
            }
        }
    }
}
