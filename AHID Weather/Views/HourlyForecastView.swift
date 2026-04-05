import SwiftUI

struct HourlyForecastView: View {
    let items: [HourlyItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    hourlyCard(item)
                }
            }
            .padding(.horizontal, 4)
        }
        .panelStyle()
    }

    private func hourlyCard(_ item: HourlyItem) -> some View {
        VStack(spacing: 6) {
            Text(item.time)
                .font(.system(size: 8, design: .monospaced))
                .tracking(2)
                .foregroundColor(ThemeColors.accentBright)

            Text(item.icon)
                .font(.system(size: 16))

            Text("\(item.temp)°")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(ThemeColors.white)

            Text("\(item.precipChance)%")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.blue.opacity(0.7))

            Text("\(item.windSpeed)mph")
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(ThemeColors.whiteDim)
        }
        .frame(minWidth: 64)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(item.isNow ? ThemeColors.accentDim : ThemeColors.void3)
        .overlay(
            Rectangle()
                .stroke(
                    item.isNow ? ThemeColors.accentBright : ThemeColors.accent.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
}
