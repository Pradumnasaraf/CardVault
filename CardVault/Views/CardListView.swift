import SwiftUI

struct CardListView: View {
    let repository: CardRepositoryProtocol

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: CardListViewModel
    @State private var showingAddCard = false

    init(repository: CardRepositoryProtocol) {
        self.repository = repository
        _viewModel = StateObject(wrappedValue: CardListViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView

                List {
                    ForEach(viewModel.cards) { card in
                        NavigationLink {
                            CardDetailsView(
                                initialCard: card,
                                repository: repository,
                                onCardUpdated: { updated in
                                    viewModel.upsert(updated)
                                }
                            )
                        } label: {
                            PaymentCardView(card: card)
                                .frame(height: 220)
                                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.requestDelete(card)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .animation(.snappy(duration: 0.28), value: viewModel.cards)

                if viewModel.cards.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView {
                        Label("No Cards Yet", systemImage: "creditcard")
                    } description: {
                        Text("Tap Add Card to store your first card securely on this device.")
                    } actions: {
                        Button("Add Card") {
                            showingAddCard = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("CardVault")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddCard = true
                    } label: {
                        Label("Add Card", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddEditCardView(repository: repository) { card in
                    viewModel.upsert(card)
                }
            }
            .alert("Delete this card?", isPresented: deleteAlertBinding) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.confirmDelete()
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
            } message: {
                Text("This permanently removes the card and deletes sensitive data from Keychain.")
            }
            .alert("Error", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .task {
                await viewModel.loadCards()
            }
            .refreshable {
                await viewModel.loadCards()
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.cardPendingDeletion != nil },
            set: { newValue in
                if !newValue {
                    viewModel.cancelDelete()
                }
            }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private var backgroundView: some View {
        let top = colorScheme == .dark
            ? Color(red: 0.08, green: 0.10, blue: 0.12)
            : Color(red: 0.97, green: 0.98, blue: 1.0)
        let bottom = colorScheme == .dark
            ? Color(red: 0.04, green: 0.05, blue: 0.07)
            : Color(red: 0.93, green: 0.95, blue: 0.98)

        return LinearGradient(
            colors: [top, bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.blue.opacity(0.1))
                .frame(width: 220, height: 220)
                .offset(x: 70, y: -80)
        }
        .ignoresSafeArea()
    }
}
