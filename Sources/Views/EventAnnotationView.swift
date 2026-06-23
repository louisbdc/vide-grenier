import SwiftUI

/// Marqueur cartographique « Carnet de chine » : badge arrondi coloré selon le
/// type d'événement, emoji de spécialité dominante, et pastille de statut
/// terrain. Les événements à éviter (annulé/vidé) sont estompés.
struct EventAnnotationView: View {
    let event: SaleEvent
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                badge
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Theme.accent, lineWidth: 3)
                                .frame(width: 46, height: 46)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        if isSelected { selectionCheck.offset(x: -6, y: -6) }
                    }
                if event.liveStatus != .scheduled {
                    statusDot
                        .offset(x: 5, y: -5)
                }
            }
            DownTriangle()
                .fill(event.kind.color)
                .frame(width: 13, height: 7)
                .offset(y: -0.5)
                .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
        }
        .opacity(event.liveStatus.isDiscouraged ? 0.55 : 1)
    }

    private var badge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(event.kind.color.gradient)
                .frame(width: 42, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(.white, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.28), radius: 3, y: 2)
            Text(topEmoji).font(.system(size: 21))
        }
    }

    private var statusDot: some View {
        ZStack {
            Circle().fill(.white).frame(width: 18, height: 18)
            Image(systemName: event.liveStatus.systemImage)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(event.liveStatus.tint)
        }
        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
    }

    private var selectionCheck: some View {
        ZStack {
            Circle().fill(Theme.accent).frame(width: 18, height: 18)
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
        }
        .overlay(Circle().stroke(.white, lineWidth: 1.5))
        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
    }

    private var topEmoji: String {
        event.topTags.first?.emoji ?? "🏷️"
    }
}
