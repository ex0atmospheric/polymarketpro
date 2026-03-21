import Foundation
import Combine

@MainActor
class PolymarketService: ObservableObject {
    @Published var markets: [Market] = []
    @Published var isLoading = false
    @Published var error: String?

    private var refreshTimer: Timer?
    // Fetch 300 so we have enough after filtering sports
    private let endpoint = "https://gamma-api.polymarket.com/markets?closed=false&limit=300&order=volume24hr&ascending=false"

    private let sportsKeywords: [String] = [
        "nfl", "nba", "mlb", "nhl", "nascar", "ncaa", "ufc", "mma", "fifa",
        "super bowl", "world cup", "champions league", "premier league",
        "la liga", "serie a", "bundesliga", "ligue 1",
        "euros", "euro 2024", "euro 2025", "euro 2026",
        "playoffs", "stanley cup", "world series", "march madness",
        "formula 1", "formula1", " f1 ", "grand prix",
        "soccer", "football", "basketball", "baseball", "hockey",
        "tennis", "golf", "cricket", "rugby", "boxing", "wrestling",
        "olympics", "olympic", "esport", "esports",
        "quarterback", "touchdown", "homerun", "slam dunk",
        "championship game", "bowl game", "transfer fee", "transfer window",
        "golden boot", "ballon d'or", "mvp award", "draft pick",
        "pga tour", "wimbledon", "us open", "french open", "australian open",
        "tour de france", "world athletics", "swimming", "gymnastics"
    ]

    private func isSports(_ market: Market) -> Bool {
        let text = [
            market.question,
            market.groupItemTitle ?? ""
        ].joined(separator: " ").lowercased()
        return sportsKeywords.contains { text.contains($0) }
    }

    init() {
        Task { await fetchMarkets() }
        startAutoRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func fetchMarkets() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let url = URL(string: endpoint) else {
            error = "Invalid URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                error = "Server error"
                return
            }
            let decoded = try JSONDecoder().decode([Market].self, from: data)
            // Filter out sports, keep top 100
            markets = decoded.filter { !isSports($0) }.prefix(100).map { $0 }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.fetchMarkets()
            }
        }
    }
}
