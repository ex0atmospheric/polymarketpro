import Foundation

struct Market: Codable, Identifiable {
    let id: String
    let question: String
    let volume24hr: Double?
    let outcomePrices: String?
    let outcomes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case question
        case volume24hr = "volume24hr"
        case outcomePrices = "outcomePrices"
        case outcomes = "outcomes"
    }

    // Parse outcomePrices JSON string e.g. "[\"0.65\",\"0.35\"]"
    private var parsedPrices: [Double] {
        guard let raw = outcomePrices,
              let data = raw.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return arr.compactMap { Double($0) }
    }

    var yesPrice: Double {
        parsedPrices.first ?? 0.5
    }

    var noPrice: Double {
        parsedPrices.count > 1 ? parsedPrices[1] : (1.0 - yesPrice)
    }

    var formattedVolume: String {
        guard let vol = volume24hr else { return "$0" }
        if vol >= 1_000_000 {
            return String(format: "$%.1fM", vol / 1_000_000)
        } else if vol >= 1_000 {
            return String(format: "$%.1fK", vol / 1_000)
        } else {
            return String(format: "$%.0f", vol)
        }
    }
}
