import SwiftUI

struct AddEditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddEditCardViewModel

    private let onSaved: (Card) -> Void

    init(repository: CardRepositoryProtocol, existingCard: Card? = nil, onSaved: @escaping (Card) -> Void) {
        _viewModel = StateObject(wrappedValue: AddEditCardViewModel(repository: repository, existingCard: existingCard))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Information") {
                    TextField("Bank Name", text: $viewModel.bankName)
                        .textInputAutocapitalization(.words)

                    TextField("Name on Card", text: $viewModel.cardholderName)
                        .textInputAutocapitalization(.words)

                    Picker("Provider", selection: $viewModel.provider) {
                        ForEach(CardProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }

                    Picker("Type", selection: $viewModel.cardType) {
                        ForEach(CardType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Card Number", text: $viewModel.cardNumber)
                        .keyboardType(.numberPad)
                        .textContentType(.creditCardNumber)

                    HStack {
                        Text("Expiry")
                        Spacer()

                        Picker("Month", selection: $viewModel.expiryMonth) {
                            ForEach(viewModel.availableExpiryMonths, id: \.self) { month in
                                Text(String(format: "%02d", month)).tag(month)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Year", selection: $viewModel.expiryYear) {
                            ForEach(viewModel.availableExpiryYears, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    SecureField("CVV", text: $viewModel.cvv)
                        .keyboardType(.numberPad)
                }

                if viewModel.cardType == .credit {
                    Section("Credit") {
                        TextField("Credit Limit (Optional)", text: $viewModel.creditLimitText)
                            .keyboardType(.decimalPad)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Section("Card Features & Info") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if viewModel.notes.isEmpty {
                                Text("Cashback offers, rewards, lounge access, etc.")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }

                Section {
                    Text("All card data remains encrypted and local to this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(viewModel.title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.actionTitle) {
                        Task {
                            if let card = await viewModel.save() {
                                onSaved(card)
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.cardType)
            .alert("Unable to Save", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .overlay {
                if viewModel.isSaving {
                    ZStack {
                        Color.black.opacity(0.15).ignoresSafeArea()
                        ProgressView("Saving...")
                            .padding(20)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
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
}
