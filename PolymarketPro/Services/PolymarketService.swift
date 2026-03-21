import Foundation
import Combine

@MainActor
class PolymarketService: ObservableObject {
    @Published var markets: [Market] = []
    @Published var isLoading = false
    @Published var error: String?

    private var refreshTimer: Timer?
    private let endpoint = "https://gamma-api.polymarket.com/markets?closed=false&limit=20&order=volume24hr&ascending=false"

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
            markets = decoded
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
