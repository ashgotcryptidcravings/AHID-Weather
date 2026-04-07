import SwiftUI

struct MetricsGridView: View {
    @ObservedObject var vm: WeatherViewModel
    @State private var selectedMetric: String? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 7)

    var body: some View {
        if let current = vm.currentWeather, let hourly = vm.hourlyWeather, let daily = vm.dailyWeather {
            let hr = Calendar.current.component(.hour, from: Date())
            let snowDepth = hr < hourly.snow_depth.count ? hourly.snow_depth[hr] : 0
            let soilTemp = hr < hourly.soil_temperature_0cm.count ? hourly.soil_temperature_0cm[hr] : 0
            let evapotrans = daily.et0_fao_evapotranspiration.first ?? 0

            // Hide snow when warm and no snow
            let rawTempF = vm.useCelsius ? current.temperature_2m * 9 / 5 + 32 : current.temperature_2m
            let showSnow = rawTempF <= 50 || snowDepth >= 0.1

            LazyVGrid(columns: dynamicColumns(showSnow: showSnow), spacing: 16) {
                metricCell(
                    id: "humidity",
                    label: "HUMIDITY",
                    value: "\(current.relative_humidity_2m)",
                    unit: "% RELATIVE",
                    suffix: "%",
                    info: "Above 70% feels muggy, below 30% dries you out. Ideal comfort: 40-60%."
                )

                metricCell(
                    id: "pressure",
                    label: "PRESSURE",
                    value: "\(Int(round(current.surface_pressure)))",
                    unit: "hPa",
                    info: "Dropping = storms coming. Rising = clearing. Rapid drops can trigger migraines."
                )

                metricCell(
                    id: "visibility",
                    label: "VISIBILITY",
                    value: String(format: "%.1f", WeatherUnits.metersToMiles(current.visibility)),
                    unit: "MILES",
                    info: "Below 1 mi = fog/heavy precip. 10+ mi = crystal clear."
                )

                metricCell(
                    id: "precipitation",
                    label: "PRECIPITATION",
                    value: String(format: "%.1f", current.precipitation),
                    unit: "mm/hr",
                    info: "0-2mm light, 2-7mm moderate, 7+ heavy downpour."
                )

                if showSnow {
                    metricCell(
                        id: "snowDepth",
                        label: "SNOW DEPTH",
                        value: String(format: "%.1f", snowDepth),
                        unit: "CM",
                        info: "Snow on ground. Lake-effect from NE winds can spike fast."
                    )
                }

                metricCell(
                    id: "evapotrans",
                    label: "EVAPOTRANS.",
                    value: String(format: "%.1f", evapotrans),
                    unit: "mm/DAY",
                    info: "Water pulled from soil/plants. Higher = drier conditions."
                )

                metricCell(
                    id: "soilTemp",
                    label: "SOIL TEMP",
                    value: "\(Int(round(soilTemp)))",
                    unit: vm.tempUnit,
                    info: "Below 32°F = frozen. Above 50°F = planting safe."
                )
            }
        }
    }

    private func dynamicColumns(showSnow: Bool) -> [GridItem] {
        #if os(iOS)
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        #else
        let count = showSnow ? 7 : 6
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: min(count, 7))
        #endif
    }

    private func metricCell(id: String, label: String, value: String, unit: String, suffix: String? = nil, info: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMetric = selectedMetric == id ? nil : id
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                Text(label)
                    .font(.system(size: 8, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(ThemeColors.accentBright)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(value)
                        .font(.system(size: 26, weight: .semibold, design: .default))
                        .foregroundColor(ThemeColors.white)
                    if let suffix = suffix {
                        Text(suffix)
                            .font(.system(size: 14))
                            .foregroundColor(ThemeColors.accentBright)
                    }
                }

                Text(unit)
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(ThemeColors.whiteDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(ThemeColors.void2)
            .overlay(
                Rectangle()
                    .stroke(
                        selectedMetric == id ? ThemeColors.accent.opacity(0.6) : ThemeColors.accent.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .overlay(alignment: .bottom) {
                if selectedMetric == id {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.accent, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(
            get: { selectedMetric == id },
            set: { if !$0 { selectedMetric = nil } }
        )) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(ThemeColors.accentBright)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundColor(ThemeColors.whiteDim)
                }

                Text(info)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ThemeColors.whiteDim)
                    .lineSpacing(4)
            }
            .padding(16)
            .frame(minWidth: 220)
            .background(ThemeColors.void2)
        }
    }
}
