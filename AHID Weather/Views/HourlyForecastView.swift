import SwiftUI

struct HourlyForecastView: View {
    let items: [HourlyItem]
    @State private var expandedId: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack(spacing: 6) {
                    ForEach(items) { item in
                        hourlyCard(item)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }

            // Expanded detail panel
            if let id = expandedId, let item = items.first(where: { $0.id == id }) {
                hourlyDetail(item)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .panelStyle()
        .animation(.easeInOut(duration: 0.2), value: expandedId)
    }

    // MARK: - Card
    private func hourlyCard(_ item: HourlyItem) -> some View {
        let isExpanded = expandedId == item.id
        return Button(action: {
            expandedId = isExpanded ? nil : item.id
        }) {
            VStack(spacing: 5) {
                Text(item.time)
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(item.isNow ? ThemeColors.accentBright : ThemeColors.accentBright.opacity(0.6))

                Text(item.icon)
                    .font(.system(size: 16))

                Text("\(item.temp)°")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ThemeColors.white)

                Text("\(item.precipChance)%")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.blue.opacity(0.7))

                Text("\(item.windSpeed)mph")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(ThemeColors.whiteDim)

                // Expand indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: 7))
                    .foregroundColor(ThemeColors.accent.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .frame(minWidth: 62)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                isExpanded ? ThemeColors.accent.opacity(0.18) :
                    item.isNow ? ThemeColors.accentDim : ThemeColors.void3
            )
            .overlay(
                Rectangle().stroke(
                    isExpanded ? ThemeColors.accentBright :
                        item.isNow ? ThemeColors.accentBright : ThemeColors.accent.opacity(0.1),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Panel
    private func hourlyDetail(_ item: HourlyItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(item.time == "NOW" ? "CURRENT HOUR DETAIL" : "\(item.time) DETAIL")
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(ThemeColors.accentBright)
                Spacer()
                Button(action: { expandedId = nil }) {
                    Text("✕")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(ThemeColors.whiteDim)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Condition description
            HStack(spacing: 10) {
                Text(item.icon).font(.system(size: 22))
                Text(item.conditionDesc.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(ThemeColors.white)
            }

            // Stats grid
            let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
            LazyVGrid(columns: cols, spacing: 8) {
                detailStat(label: "TEMP",     value: "\(item.temp)°")
                detailStat(label: "FEELS",    value: "\(item.feelsLike)°")
                detailStat(label: "HUMIDITY", value: "\(item.humidity)%")
                detailStat(label: "PRECIP",   value: "\(item.precipChance)%")
                detailStat(label: "WIND",     value: "\(item.windSpeed) mph")
                detailStat(label: "DIRECTION",value: item.windCompass)
                detailStat(label: "BEAUFORT", value: WindHelper.beaufort(Double(item.windSpeed)).components(separatedBy: " · ").last ?? "")
                detailStat(label: "DEW PT.",  value: humidityComfort(item.humidity))
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 4)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ThemeColors.accent.opacity(0.2))
                .frame(height: 1)
        }
    }

    private func detailStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 7, design: .monospaced))
                .tracking(1)
                .foregroundColor(ThemeColors.accentBright.opacity(0.7))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ThemeColors.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(ThemeColors.void3)
        .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.1), lineWidth: 1))
    }

    private func humidityComfort(_ h: Int) -> String {
        if h < 30 { return "DRY" }
        if h < 50 { return "COMFY" }
        if h < 70 { return "HUMID" }
        return "MUGGY"
    }
}
