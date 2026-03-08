import SwiftUI

struct CardDetailsView: View {
    let repository: CardRepositoryProtocol
    let onCardUpdated: (Card) -> Void
    let onCardDeleted: ((UUID) -> Void)?

    @StateObject private var viewModel: CardDetailsViewModel
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false

    init(
        initialCard: Card,
        repository: CardRepositoryProtocol,
        onCardUpdated: @escaping (Card) -> Void,
        onCardDeleted: ((UUID) -> Void)? = nil
    ) {
        self.repository = repository
        self.onCardUpdated = onCardUpdated
        self.onCardDeleted = onCardDeleted
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let onCardDeleted {
                    Menu {
                        Button("Edit") {
                            showingEdit = true
                        }
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Delete Card", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .accessibilityLabel("Card options")
                    }
                } else {
                    Button("Edit") {
                        showingEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditCardView(repository: repository, existingCard: viewModel.card) { updated in
                viewModel.updateCard(updated)
                onCardUpdated(updated)
            }
        }
        .confirmationDialog("Delete Card", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                performDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This card will be permanently removed from CardVault. This cannot be undone.")
        }
    }

    private func performDelete() {
        guard let onCardDeleted else { return }
        onCardDeleted(viewModel.card.id)
    }
}
