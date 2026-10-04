import SwiftUI

/// "Shop your routine": every step in her consultation's plan, morning and evening, each with
/// a shop link for that kind of product. Matched to her consult, no placeholder brands.
struct RoutineShopView: View {
    let plan: Consult.Plan
    let onShop: (String) -> Void

    private struct Step: Identifiable {
        let name: String
        let when: String
        var id: String { name.lowercased() }
    }

    /// Plan steps in order, each once, tagged with when she uses it.
    private var steps: [Step] {
        var order: [String] = []
        var times: [String: Set<String>] = [:]
        for (list, time) in [(plan.morning, "Morning"), (plan.evening, "Evening")] {
            for raw in list {
                let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let key = name.lowercased()
                if times[key] == nil { order.append(name) }
                times[key, default: []].insert(time)
            }
        }
        return order.map { name in
            let when = times[name.lowercased()] ?? []
            return Step(name: name, when: when.count == 2 ? "Morning & evening" : (when.first ?? ""))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SHOP YOUR ROUTINE")
                .font(FLFont.sans(10, .semibold))
                .tracking(1.8)
                .foregroundStyle(Palette.stone)
            Text("Each step from your consultation. Keep what you already own, and shop only what's missing.")
                .font(FLFont.sans(13))
                .foregroundStyle(Palette.pebble)
                .lineSpacing(4)
                .padding(.top, 8)

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    if index > 0 { Rectangle().fill(Palette.rowDivider).frame(height: 1) }
                    Button { onShop(step.name) } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(step.name)
                                    .font(FLFont.sans(14.5, .medium))
                                    .foregroundStyle(Palette.ink)
                                    .multilineTextAlignment(.leading)
                                Text(step.when)
                                    .font(FLFont.sans(11.5))
                                    .foregroundStyle(Palette.stone)
                            }
                            Spacer(minLength: 8)
                            Text("Shop ›")
                                .font(FLFont.sans(13, .semibold))
                                .foregroundStyle(Palette.rose)
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle(scale: 0.98))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
            .cardSurface(radius: 20)
            .padding(.top, 14)
        }
        .padding(.horizontal, 24)
    }
}
