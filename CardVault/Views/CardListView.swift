import SwiftUI

struct CardListView: View {
    let repository: CardRepositoryProtocol
    let authenticationService: AuthenticationServicing

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: CardListViewModel
    @State private var showingAddCard = false
    @State private var selectedSettingsCard: Card?
    @State private var revealedCardIDs: Set<UUID> = []
    @State private var revealTasks: [UUID: Task<Void, Never>] = [:]
    @State private var revealErrorMessage: String?
    @State private var settingsAuthErrorMessage: String?

    init(repository: CardRepositoryProtocol, authenticationService: AuthenticationServicing) {
        self.repository = repository
        self.authenticationService = authenticationService
        _viewModel = StateObject(wrappedValue: CardListViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView

                List {
                    ForEach(viewModel.cards) { card in
                        HStack {
                            Spacer(minLength: 0)
                            PaymentCardView(
                                card: card,
                                revealSensitive: revealedCardIDs.contains(card.id),
                                onVisibilityTap: {
                                    handleVisibilityTap(card)
                                }
                            )
                            .frame(maxWidth: 390)
                            .frame(height: 232)
                            Spacer(minLength: 0)
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                openSettings(card)
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                            .tint(.gray)
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
            .navigationBarTitleDisplayMode(.large)
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
            .sheet(item: $selectedSettingsCard) { card in
                NavigationStack {
                    CardDetailsView(
                        initialCard: card,
                        repository: repository,
                        onCardUpdated: { updated in
                            handleCardUpdated(updated)
                        }
                    )
                }
            }
            .alert("Unable to Open Settings", isPresented: settingsErrorAlertBinding) {
                Button("OK", role: .cancel) {
                    settingsAuthErrorMessage = nil
                }
            } message: {
                Text(settingsAuthErrorMessage ?? "Authentication failed.")
            }
            .alert("Unable to Reveal Card", isPresented: revealErrorAlertBinding) {
                Button("OK", role: .cancel) {
                    revealErrorMessage = nil
                }
            } message: {
                Text(revealErrorMessage ?? "Authentication failed.")
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
            .onChange(of: viewModel.cards) { _, newCards in
                let cardIDs = Set(newCards.map(\.id))
                revealedCardIDs.formIntersection(cardIDs)
                for id in revealTasks.keys where !cardIDs.contains(id) {
                    revealTasks[id]?.cancel()
                    revealTasks[id] = nil
                }
            }
            .onDisappear {
                for task in revealTasks.values {
                    task.cancel()
                }
                revealTasks.removeAll()
            }
        }
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

    private var revealErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { revealErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    revealErrorMessage = nil
                }
            }
        )
    }

    private var settingsErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { settingsAuthErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    settingsAuthErrorMessage = nil
                }
            }
        )
    }

    private func handleVisibilityTap(_ card: Card) {
        if revealedCardIDs.contains(card.id) {
            concealCard(id: card.id)
            return
        }

        Task {
            do {
                try await authenticationService.authenticate(reason: "Reveal sensitive card details")
                await MainActor.run {
                    revealCard(id: card.id)
                }
            } catch {
                await MainActor.run {
                    revealErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func openSettings(_ card: Card) {
        Task {
            do {
                try await authenticationService.authenticate(reason: "Open card settings")
                await MainActor.run {
                    selectedSettingsCard = card
                }
            } catch {
                await MainActor.run {
                    settingsAuthErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func revealCard(id: UUID) {
        revealTasks[id]?.cancel()
        revealedCardIDs.insert(id)

        revealTasks[id] = Task {
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                concealCard(id: id)
            }
        }
    }

    private func concealCard(id: UUID) {
        revealedCardIDs.remove(id)
        revealTasks[id]?.cancel()
        revealTasks[id] = nil
    }

    private func handleCardUpdated(_ card: Card) {
        viewModel.upsert(card)

        if selectedSettingsCard?.id == card.id {
            selectedSettingsCard = card
        }
    }

    private var backgroundView: some View {
        let top = colorScheme == .dark
            ? Color(red: 0.10, green: 0.12, blue: 0.18)
            : Color(red: 0.98, green: 0.96, blue: 0.90)
        let bottom = colorScheme == .dark
            ? Color(red: 0.06, green: 0.08, blue: 0.12)
            : Color(red: 0.90, green: 0.94, blue: 0.98)

        return LinearGradient(
            colors: [top, bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.18 : 0.28))
                .frame(width: 260, height: 260)
                .offset(x: -90, y: 80)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.indigo.opacity(colorScheme == .dark ? 0.20 : 0.14))
                .frame(width: 240, height: 240)
                .offset(x: 70, y: -70)
        }
        .ignoresSafeArea()
    }
}
