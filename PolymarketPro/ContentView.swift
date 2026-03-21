import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case liveMarkets = "Live Markets"
    case aiAnalyst = "AI Analyst"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:   return "chart.pie.fill"
        case .liveMarkets: return "chart.line.uptrend.xyaxis"
        case .aiAnalyst:   return "brain.head.profile"
        case .settings:    return "gearshape.fill"
        }
    }

    var emoji: String {
        switch self {
        case .dashboard:   return "📊"
        case .liveMarkets: return "📈"
        case .aiAnalyst:   return "🤖"
        case .settings:    return "⚙️"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            Group {
                switch selection {
                case .dashboard, .none:
                    DashboardView()
                case .liveMarkets:
                    MarketListView()
                case .aiAnalyst:
                    AIAnalystView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#080a0f"))
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        VStack(spacing: 0) {
            // Logo / title area
            HStack(spacing: 10) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundColor(Color(hex: "#4f8ef7"))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Polymarket")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Pro")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#4f8ef7"))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.bottom, 8)

            // Navigation items
            ForEach(SidebarItem.allCases) { item in
                SidebarRowView(item: item, isSelected: selection == item)
                    .onTapGesture { selection = item }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
            }

            Spacer()

            Divider()
                .background(Color.white.opacity(0.08))

            // Version footer
            Text("PolymarketPro v1.0")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.25))
                .padding(.vertical, 10)
        }
        .background(Color(hex: "#0e1117"))
        .listStyle(.sidebar)
    }
}

struct SidebarRowView: View {
    let item: SidebarItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? Color(hex: "#4f8ef7") : Color.white.opacity(0.5))
                .frame(width: 20)
            Text(item.rawValue)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.65))
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(hex: "#4f8ef7").opacity(0.18) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @StateObject private var marketService = PolymarketService()

    var body: some View {
        ZStack {
            Color(hex: "#080a0f").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Prediction market overview")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 4)

                    // Stats row
                    HStack(spacing: 14) {
                        StatCard(
                            title: "Markets Tracked",
                            value: "\(marketService.markets.count)",
                            icon: "chart.bar.fill",
                            color: Color(hex: "#4f8ef7")
                        )
                        StatCard(
                            title: "Avg Yes Price",
                            value: marketService.markets.isEmpty ? "—" :
                                String(format: "%.1f%%", marketService.markets.map(\.yesPrice).reduce(0, +) / Double(marketService.markets.count) * 100),
                            icon: "arrow.up.circle.fill",
                            color: Color(hex: "#10d67d")
                        )
                        StatCard(
                            title: "Total 24h Vol",
                            value: totalVolume,
                            icon: "dollarsign.circle.fill",
                            color: Color(hex: "#f04f5a")
                        )
                    }

                    // Top markets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top Markets by Volume")
                            .font(.headline)
                            .foregroundColor(.white)

                        if marketService.isLoading && marketService.markets.isEmpty {
                            ProgressView()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(marketService.markets.prefix(5)) { market in
                                DashboardMarketRow(market: market)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var totalVolume: String {
        let total = marketService.markets.compactMap(\.volume24hr).reduce(0, +)
        if total >= 1_000_000 { return String(format: "$%.1fM", total / 1_000_000) }
        if total >= 1_000 { return String(format: "$%.1fK", total / 1_000) }
        return "$0"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#0e1117"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct DashboardMarketRow: View {
    let market: Market

    var body: some View {
        HStack(spacing: 12) {
            // Probability indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: market.yesPrice)
                    .stroke(
                        market.yesPrice >= 0.5 ? Color(hex: "#10d67d") : Color(hex: "#f04f5a"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 40, height: 40)
                Text(String(format: "%.0f", market.yesPrice * 100))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(market.question)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(market.formattedVolume)
                    .font(.caption2)
                    .foregroundColor(Color(hex: "#4f8ef7"))
            }

            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#0e1117"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Color extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
