import SwiftUI

/// Grille de tags d'inventaire que le visiteur attribue en direct.
struct TagChipsView: View {
    let onSelect: (InventoryTag) -> Void

    private let columns = [GridItem(.adaptive(minimum: 116), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(InventoryTag.allCases) { tag in
                Button { onSelect(tag) } label: {
                    HStack(spacing: 7) {
                        Text(tag.emoji)
                        Text(tag.label)
                            .font(Theme.display(14, .medium))
                            .foregroundStyle(Theme.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .background(Theme.accent.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Theme.accent.opacity(0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
