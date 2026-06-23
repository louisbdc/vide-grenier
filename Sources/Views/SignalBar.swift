import SwiftUI

/// Boutons de signalement « terrain » en un tap : annulé, foule, désert, vidé…
/// Chaque action porte la couleur de son statut pour une lecture immédiate.
struct SignalBar: View {
    let onSelect: (SignalType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SignalType.allCases) { type in
                    Button { onSelect(type) } label: {
                        Label(type.label, systemImage: type.systemImage)
                            .font(Theme.display(14, .semibold))
                            .foregroundStyle(type.tint)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 11)
                            .background(type.tint.opacity(0.13), in: Capsule())
                            .overlay(Capsule().stroke(type.tint.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private extension SignalType {
    /// Couleur cohérente avec le statut affiché sur la carte.
    var tint: Color {
        switch self {
        case .ongoing: return Theme.teal
        case .crowded: return Theme.ochre
        case .deserted: return Theme.slate
        case .emptied: return Theme.slate
        case .cancelled: return Theme.terracotta
        }
    }
}
