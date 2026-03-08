import SwiftUI

struct PaymentCardView: View {
    let card: Card
    var revealNumber: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(gradient)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.12 : 0.22))

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(card.bankName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        Image(systemName: card.provider.logoSymbolName)
                        Text(card.provider.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.95))
                }

                Spacer(minLength: 0)

                Text(displayNumber)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EXPIRY")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.75))
                        Text(card.expiryDate)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }

                    Spacer()

                    Text(card.cardType.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.16), in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .padding(22)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.2), radius: 20, y: 10)
    }

    private var displayNumber: String {
        revealNumber
            ? CardFormatting.formatCardNumber(card.cardNumber)
            : card.maskedNumber
    }

    private var gradient: LinearGradient {
        switch card.provider {
        case .visa:
            return LinearGradient(colors: [Color(red: 0.07, green: 0.25, blue: 0.73), Color(red: 0.06, green: 0.50, blue: 0.98)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .masterCard:
            return LinearGradient(colors: [Color(red: 0.79, green: 0.22, blue: 0.14), Color(red: 0.95, green: 0.58, blue: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .americanExpress:
            return LinearGradient(colors: [Color(red: 0.03, green: 0.45, blue: 0.56), Color(red: 0.18, green: 0.73, blue: 0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .discover:
            return LinearGradient(colors: [Color(red: 0.19, green: 0.18, blue: 0.20), Color(red: 0.95, green: 0.43, blue: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:
            return LinearGradient(colors: [Color(red: 0.16, green: 0.22, blue: 0.28), Color(red: 0.35, green: 0.43, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
