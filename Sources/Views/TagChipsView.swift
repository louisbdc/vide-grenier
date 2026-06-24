import SwiftUI

/// Grille de tags d'inventaire que le visiteur attribue en direct.
/// Les tags déjà signalés par l'utilisateur restent mis en évidence (✓).
struct TagChipsView: View {
    let onSelect: (InventoryTag) -> Void

    @State private var added: Set<InventoryTag> = []

    private let columns = [GridItem(.adaptive(minimum: 116), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(InventoryTag.allCases) { tag in
                let isOn = added.contains(tag)
                Button {
                    added.insert(tag)
                    onSelect(tag)
                } label: {
                    HStack(spacing: 7) {
                        Text(tag.emoji)
                        Text(tag.label)
                            .font(Theme.display(14, isOn ? .semibold : .medium))
                            .foregroundStyle(isOn ? .white : Theme.ink)
                        Spacer(minLength: 0)
                        if isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .background(isOn ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.accent.opacity(0.08)),
                                in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Theme.accent.opacity(isOn ? 0 : 0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(isOn ? "Déjà ajouté" : "Double-tape pour signaler cet article")
            }
        }
        .animation(.snappy(duration: 0.2), value: added)
        .sensoryFeedback(.success, trigger: added)
    }
}
