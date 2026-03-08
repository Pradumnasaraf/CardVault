import SwiftUI

struct DetailInfoRow: View {
    let title: String
    let value: String
    var isSensitive: Bool = false
    var actionIcon: String = "eye"
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(isSensitive ? .system(.body, design: .monospaced).weight(.medium) : .body.weight(.medium))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }

            Spacer()

            if let action {
                Button(action: action) {
                    Image(systemName: actionIcon)
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .tint(.secondary)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
