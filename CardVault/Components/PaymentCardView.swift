import SwiftUI
import UIKit

struct PaymentCardView: View {
    let card: Card
    var revealSensitive: Bool = false
    var onVisibilityTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @State private var toastMessage: String?
    @State private var toastDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(gradient)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.15 : 0.18))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.24), lineWidth: 1)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text(card.bankName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 10)
                }

                LabeledSensitiveValue(
                    title: "CARD NUMBER",
                    value: displayNumber,
                    showCopy: revealSensitive,
                    copyValue: card.cardNumber,
                    onCopy: copyToClipboard
                )

                HStack {
                    LabeledSensitiveValue(
                        title: "EXPIRY",
                        value: card.expiryDate,
                        showCopy: revealSensitive,
                        copyValue: card.expiryDate,
                        onCopy: copyToClipboard
                    )

                    Spacer()

                    LabeledSensitiveValue(
                        title: "CVV",
                        value: revealSensitive ? card.cvv : "***",
                        showCopy: revealSensitive,
                        copyValue: card.cvv,
                        onCopy: copyToClipboard
                    )

                    Spacer()
                    Group {
                        if card.cardType == .credit {
                            LabeledSensitiveValue(
                                title: "LIMIT",
                                value: limitDisplayValue,
                                showCopy: false,
                                copyValue: nil,
                                onCopy: nil
                            )
                        } else {
                            // Keep CVV position consistent between debit and credit cards.
                            Color.clear
                                .frame(width: 80, height: 34)
                        }
                    }
                }

                if !card.cardholderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledSensitiveValue(
                        title: "NAME",
                        value: card.cardholderName.uppercased(),
                        showCopy: false,
                        copyValue: nil,
                        onCopy: nil
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .overlay(alignment: .topTrailing) {
            ProviderLogoView(provider: card.provider)
                .padding(.top, 14)
                .padding(.trailing, 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(revealSensitive ? "Card details revealed" : "Double tap to reveal card details")
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 110, height: 110)
                .offset(x: 30, y: 28)
        }
        .overlay(alignment: .bottomTrailing) {
            if let onVisibilityTap {
                Button(action: onVisibilityTap) {
                    Image(systemName: revealSensitive ? "eye.slash.fill" : "eye.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.30), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(revealSensitive ? "Conceal card details" : "Reveal card details")
                .accessibilityHint("Requires Face ID")
                .padding(.bottom, 14)
                .padding(.trailing, 14)
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.72), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toastMessage)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.2), radius: 20, y: 10)
    }

    private var accessibilityLabel: String {
        let bank = card.bankName
        let last4 = card.last4
        let provider = card.provider.rawValue
        if revealSensitive {
            return "\(bank) \(provider) card ending in \(last4), full number visible"
        } else {
            return "\(bank) \(provider) card ending in \(last4), details hidden"
        }
    }

    private var displayNumber: String {
        revealSensitive
            ? CardFormatting.formatCardNumber(card.cardNumber)
            : card.maskedNumber
    }

    private var limitDisplayValue: String {
        guard let creditLimit = card.creditLimit else { return "N/A" }
        return NumberFormatter.currency.string(from: NSDecimalNumber(decimal: creditLimit)) ?? "\(creditLimit)"
    }

    private var gradient: LinearGradient {
        switch card.provider {
        case .visa:
            return LinearGradient(colors: [Color(red: 0.02, green: 0.23, blue: 0.62), Color(red: 0.14, green: 0.56, blue: 0.96)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .masterCard:
            return LinearGradient(colors: [Color(red: 0.66, green: 0.10, blue: 0.14), Color(red: 0.98, green: 0.58, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .americanExpress:
            return LinearGradient(colors: [Color(red: 0.00, green: 0.37, blue: 0.60), Color(red: 0.05, green: 0.71, blue: 0.80)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .discover:
            return LinearGradient(colors: [Color(red: 0.17, green: 0.17, blue: 0.20), Color(red: 0.94, green: 0.43, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ruPay:
            return LinearGradient(colors: [Color(red: 0.00, green: 0.30, blue: 0.62), Color(red: 0.16, green: 0.62, blue: 0.40)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:
            return LinearGradient(colors: [Color(red: 0.20, green: 0.24, blue: 0.28), Color(red: 0.42, green: 0.48, blue: 0.56)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value

        toastDismissTask?.cancel()
        toastMessage = "Copied"
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    toastMessage = nil
                }
            }
        }
    }
}

private struct ProviderLogoView: View {
    let provider: CardProvider

    var body: some View {
        Group {
            if let asset = provider.logoAssetName {
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: logoWidth, height: logoHeight, alignment: .trailing)
                    .offset(x: logoOffsetX)
            } else {
                Image(systemName: "creditcard.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .frame(width: 92, height: 30, alignment: .trailing)
        .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
    }

    private var logoWidth: CGFloat {
        switch provider {
        case .visa:
            return 74
        case .masterCard:
            return 64
        case .americanExpress:
            return 44
        case .discover:
            return 80
        case .ruPay:
            return 82
        case .other:
            return 24
        }
    }

    private var logoHeight: CGFloat {
        switch provider {
        case .americanExpress:
            return 22
        case .masterCard:
            return 28
        default:
            return 24
        }
    }

    private var logoOffsetX: CGFloat {
        switch provider {
        case .americanExpress:
            return 2
        default:
            return 0
        }
    }
}

private struct LabeledSensitiveValue: View {
    let title: String
    let value: String
    let showCopy: Bool
    let copyValue: String?
    let onCopy: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))

                if showCopy, let copyValue {
                    Button {
                        onCopy?(copyValue)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy \(title)")
                }
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
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
