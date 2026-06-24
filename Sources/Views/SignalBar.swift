import SwiftUI

/// Boutons de signalement « terrain » en un tap : annulé, foule, désert, vidé…
/// Chaque action porte la couleur de son statut pour une lecture immédiate.
/// Les statuts déjà signalés par l'utilisateur restent mis en évidence (✓).
struct SignalBar: View {
    let onSelect: (SignalType) -> Void

    @State private var signaled: Set<SignalType> = []

    var body: some View {
        FlowLayout(spacing: 10) {
            ForEach(SignalType.allCases) { type in
                let isOn = signaled.contains(type)
                Button {
                    signaled.insert(type)
                    onSelect(type)
                } label: {
                    Label {
                        Text(type.label)
                    } icon: {
                        Image(systemName: isOn ? "checkmark" : type.systemImage)
                    }
                    .font(Theme.display(14, .semibold))
                    .foregroundStyle(isOn ? .white : type.tint)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 11)
                    .background(isOn ? AnyShapeStyle(type.tint) : AnyShapeStyle(type.tint.opacity(0.13)),
                                in: .capsule)
                    .overlay(Capsule().stroke(type.tint.opacity(isOn ? 0 : 0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityHint(isOn ? "Déjà signalé" : "Double-tape pour signaler")
            }
        }
        .animation(.snappy(duration: 0.2), value: signaled)
        .sensoryFeedback(.success, trigger: signaled)
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
