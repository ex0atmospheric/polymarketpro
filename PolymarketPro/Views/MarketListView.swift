import SwiftUI

struct MarketListView: View {
    @StateObject private var service = PolymarketService()

    var body: some View {
        ZStack {
            Color(hex: "#080a0f").ignoresSafeArea()

            if service.isLoading && service.markets.isEmpty {
                ProgressView("Loading markets…")
                    .foregroundColor(.white)
            } else if let err = service.error, service.markets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: "#f04f5a"))
                    Text(err)
                        .foregroundColor(.white)
                    Button("Retry") {
                        Task { await service.fetchMarkets() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#4f8ef7"))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(service.markets) { market in
                            MarketRowView(market: market)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Live Markets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await service.fetchMarkets() }
                } label: {
                    if service.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(hex: "#4f8ef7"))
                    }
                }
                .disabled(service.isLoading)
            }
        }
    }
}

struct MarketRowView: View {
    let market: Market

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(market.question)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                // Yes probability bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("YES")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#10d67d"))
                        Spacer()
                        Text(String(format: "%.1f%%", market.yesPrice * 100))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#10d67d"))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "#10d67d"))
                                .frame(width: geo.size.width * market.yesPrice, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                // No probability bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("NO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#f04f5a"))
                        Spacer()
                        Text(String(format: "%.1f%%", market.noPrice * 100))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#f04f5a"))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "#f04f5a"))
                                .frame(width: geo.size.width * market.noPrice, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }

            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption2)
                    .foregroundColor(Color(hex: "#4f8ef7"))
                Text("24h Vol: \(market.formattedVolume)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#4f8ef7"))
                Spacer()
                // Probability dot indicator
                Circle()
                    .fill(probabilityColor(market.yesPrice))
                    .frame(width: 8, height: 8)
                Text(probabilityLabel(market.yesPrice))
                    .font(.caption2)
                    .foregroundColor(probabilityColor(market.yesPrice))
            }
        }
        .padding(14)
        .background(Color(hex: "#0e1117"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func probabilityColor(_ p: Double) -> Color {
        if p >= 0.7 { return Color(hex: "#10d67d") }
        if p <= 0.3 { return Color(hex: "#f04f5a") }
        return Color(hex: "#4f8ef7")
    }

    private func probabilityLabel(_ p: Double) -> String {
        if p >= 0.7 { return "Likely YES" }
        if p <= 0.3 { return "Likely NO" }
        return "Contested"
    }
}
