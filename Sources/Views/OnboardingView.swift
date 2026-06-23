import SwiftUI

/// Accueil du premier lancement : pose l'identité et la promesse (zéro pub,
/// temps réel, couverture nationale) avant de demander la localisation.
struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let message: String
    }

    private let pages: [Page] = [
        Page(symbol: "map.fill",
             title: "Toute la chine,\nsur une carte",
             message: "Vide-greniers, brocantes et marchés aux puces de toute la France, en temps réel autour de toi."),
        Page(symbol: "hand.raised.slash.fill",
             title: "Zéro pub.\nVraiment.",
             message: "Gratuit pour les chineurs, sans bannière, sans redirection. On ne te vend pas, on t'aide à chiner."),
        Page(symbol: "dot.radiowaves.left.and.right",
             title: "Le terrain,\nen direct",
             message: "Foule, événement annulé, stand vidé, « beaucoup de puériculture »… La communauté signale, tu ajustes ton parcours."),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.terracotta, Theme.ochre],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item).tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 { withAnimation { page += 1 } } else { onFinish() }
                } label: {
                    Text(page < pages.count - 1 ? "Continuer" : "Commencer la chine")
                        .font(Theme.display(17, .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.white)
                .foregroundStyle(Theme.terracotta)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 78, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            Text(item.title)
                .font(Theme.display(34, .heavy))
                .multilineTextAlignment(.center)
            Text(item.message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .foregroundStyle(.white)
        .padding()
    }
}
