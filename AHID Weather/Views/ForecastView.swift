import SwiftUI

struct ForecastView: View {
    @ObservedObject var vm: WeatherViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            BlockLabel(text: "7-DAY FORECAST", hint: "TAP A DAY")

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(vm.forecastDays) { day in
                    forecastDayCard(day)
                }
            }

            // Detail panel
            if let index = vm.selectedForecastIndex, index < vm.forecastDays.count {
                forecastDetail(vm.forecastDays[index])
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .panelStyle()
    }

    private func forecastDayCard(_ day: ForecastDay) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { vm.selectForecastDay(day.index) } }) {
            VStack(spacing: 8) {
                Text(day.dayName)
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(ThemeColors.accentBright)

                Text(day.icon)
                    .font(.system(size: 22))

                Text("\(day.high)°")
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(ThemeColors.white)

                Text("\(day.low)°")
                    .font(.system(size: 11))
                    .foregroundColor(ThemeColors.whiteDim)

                Text("\(day.precipChance)%")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.blue.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                day.isToday ? ThemeColors.accentDim :
                    vm.selectedForecastIndex == day.index ? Color(red: 0.486, green: 0.227, blue: 0.929).opacity(0.12) :
                    ThemeColors.void3
            )
            .overlay(
                Rectangle()
                    .stroke(
                        vm.selectedForecastIndex == day.index ? ThemeColors.accentBright :
                            day.isToday ? ThemeColors.accent.opacity(0.5) :
                            ThemeColors.accent.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func forecastDetail(_ day: ForecastDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day.dateString)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .tracking(1)
                    .foregroundColor(ThemeColors.accentBright)

                Spacer()

                Button(action: {
                    withAnimation { vm.selectedForecastIndex = nil; vm.forecastAISummary = nil }
                }) {
                    Text("CLOSE ✕")
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(ThemeColors.whiteDim)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Stats row
            HStack(spacing: 0) {
                statItem("HIGH", "\(day.high)\(vm.tempUnit)")
                Text(" · ").foregroundColor(ThemeColors.whiteDim)
                statItem("LOW", "\(day.low)\(vm.tempUnit)")
                Text(" · ").foregroundColor(ThemeColors.whiteDim)
                Text(day.condition.uppercased())
                    .foregroundColor(ThemeColors.whiteDim)
                Text(" · ").foregroundColor(ThemeColors.whiteDim)
                statItem("PRECIP", "\(day.precipChance)%")
                Text(" · ").foregroundColor(ThemeColors.whiteDim)
                statItem("UV", String(format: "%.1f", day.uvMax))
                Text(" · ☀ \(day.sunrise)–\(day.sunset)")
                    .foregroundColor(ThemeColors.whiteDim)
            }
            .font(.system(size: 10, design: .monospaced))
            .lineLimit(1)

            // AI Summary
            VStack(alignment: .leading, spacing: 4) {
                Text("AI ANALYSIS")
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(ThemeColors.accentBright)

                if vm.isForecastAILoading {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(ThemeColors.accentBright)
                                .frame(width: 4, height: 4)
                                .opacity(0.3)
                        }
                    }
                    .padding(.top, 4)
                } else if let summary = vm.forecastAISummary {
                    Text(summary)
                        .font(.system(size: 11, design: .default))
                        .foregroundColor(ThemeColors.whiteDim)
                        .lineSpacing(4)
                }
            }
            .padding(.leading, 12)
            .overlay(
                Rectangle()
                    .fill(ThemeColors.accent.opacity(0.3))
                    .frame(width: 2),
                alignment: .leading
            )
        }
        .padding(18)
        .background(ThemeColors.void3)
        .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.25), lineWidth: 1))
        .padding(.top, 12)
    }

    private func statItem(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundColor(ThemeColors.whiteDim)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(ThemeColors.white)
        }
    }
}
