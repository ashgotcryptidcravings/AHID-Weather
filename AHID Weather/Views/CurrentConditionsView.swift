import SwiftUI

struct CurrentConditionsView: View {
    @ObservedObject var vm: WeatherViewModel

    var body: some View {
        if let current = vm.currentWeather, let daily = vm.dailyWeather {
            HStack(alignment: .top, spacing: 16) {
                // Hero - Temperature
                heroBlock(current: current, daily: daily)
                    .frame(maxWidth: .infinity)

                // Wind + UV
                windUVBlock(current: current)
                    .frame(maxWidth: .infinity)

                // AQI + Cloud
                aqiBlock(current: current)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Hero Block
    @ViewBuilder
    private func heroBlock(current: CurrentWeather, daily: DailyWeather) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CURRENT TEMPERATURE")
                .font(.system(size: 9, design: .monospaced))
                .tracking(4)
                .foregroundColor(ThemeColors.accentBright)
                .padding(.bottom, 8)

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(Int(round(current.temperature_2m)))")
                    .font(.system(size: 88, weight: .light, design: .default))
                    .foregroundColor(ThemeColors.white)

                Text(vm.tempUnit)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(ThemeColors.accentBright)
                    .baselineOffset(40)
            }

            Text(WeatherCode.description(for: current.weather_code))
                .font(.system(size: 18, weight: .regular, design: .default))
                .foregroundColor(ThemeColors.whiteDim)
                .padding(.top, 8)

            HStack(spacing: 0) {
                Text("FEELS LIKE ")
                    .foregroundColor(ThemeColors.whiteDim)
                Text("\(Int(round(current.apparent_temperature)))\(vm.tempUnit)")
                    .foregroundColor(ThemeColors.white)
                Text("  ·  DEW POINT ")
                    .foregroundColor(ThemeColors.whiteDim)
                Text("\(Int(round(current.dew_point_2m)))\(vm.tempUnit)")
                    .foregroundColor(ThemeColors.white)
            }
            .font(.system(size: 10, design: .monospaced))
            .tracking(1)
            .padding(.top, 6)

            // Sunrise / Sunset / Daylight
            HStack(spacing: 12) {
                sunItem(icon: "☀", label: "SUNRISE", value: WeatherUnits.formatTime(daily.sunrise[0]))
                sunItem(icon: "◑", label: "SUNSET", value: WeatherUnits.formatTime(daily.sunset[0]))
                sunItem(icon: "◐", label: "DAYLIGHT", value: WeatherUnits.daylightHours(sunrise: daily.sunrise[0], sunset: daily.sunset[0]))
            }
            .padding(.top, 16)
        }
        .panelStyle()
        .overlay(
            Rectangle()
                .fill(ThemeColors.accentBright)
                .frame(width: 2),
            alignment: .leading
        )
    }

    private func sunItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 18))
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .tracking(2)
                .foregroundColor(ThemeColors.accentBright)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(ThemeColors.white)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(ThemeColors.void3)
        .overlay(
            Rectangle().stroke(ThemeColors.accent.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Wind + UV Block
    @ViewBuilder
    private func windUVBlock(current: CurrentWeather) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Wind section
            VStack(alignment: .leading, spacing: 0) {
                BlockLabel(text: "WIND")

                HStack(spacing: 20) {
                    // Compass
                    WindCompass(degrees: current.wind_direction_10m)
                        .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(round(current.wind_speed_10m)))")
                                .font(.system(size: 38, weight: .semibold, design: .default))
                                .foregroundColor(ThemeColors.white)
                            Text("mph")
                                .font(.system(size: 14))
                                .foregroundColor(ThemeColors.whiteDim)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            windDetail("DIRECTION", WindHelper.degreeToCompass(current.wind_direction_10m))
                            windDetail("GUSTS", "\(Int(round(current.wind_gusts_10m))) mph")
                            windDetail("BEAUFORT", WindHelper.beaufort(current.wind_speed_10m))
                        }
                    }
                }
            }

            // UV section
            VStack(alignment: .leading, spacing: 0) {
                BlockLabel(text: "UV INDEX")

                Text(String(format: "%.1f", current.uv_index))
                    .font(.system(size: 32, weight: .semibold, design: .default))
                    .foregroundColor(ThemeColors.white)

                UVBar(value: current.uv_index)
                    .padding(.top, 8)

                Text(UVHelper.label(current.uv_index))
                    .font(.system(size: 10, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(ThemeColors.accentBright)
                    .padding(.top, 6)
            }
        }
        .panelStyle()
    }

    private func windDetail(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .foregroundColor(ThemeColors.whiteDim)
            Text(value)
                .foregroundColor(ThemeColors.white)
        }
        .font(.system(size: 10, design: .monospaced))
        .tracking(1)
    }

    // MARK: - AQI Block
    @ViewBuilder
    private func aqiBlock(current: CurrentWeather) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            BlockLabel(text: "AIR QUALITY INDEX")

            let aqi = vm.aqiValue
            let cat = vm.aqiCategory

            Text("\(aqi)")
                .font(.system(size: 52, weight: .semibold, design: .default))
                .foregroundColor(cat.color)
                .padding(.top, 8)

            Text(cat.label)
                .font(.system(size: 11, design: .monospaced))
                .tracking(2)
                .foregroundColor(cat.color)
                .padding(.top, 4)

            // AQI bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(ThemeColors.void4)
                        .frame(height: 4)
                    Rectangle()
                        .fill(cat.color)
                        .frame(width: geo.size.width * min(Double(aqi) / 300.0, 1.0), height: 4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .frame(height: 4)
            .padding(.top, 12)

            HStack {
                Text("GOOD").frame(maxWidth: .infinity, alignment: .leading)
                Text("MOD")
                Text("USG")
                Text("UNHEALTHY")
                Text("HAZ").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 8, design: .monospaced))
            .tracking(1)
            .foregroundColor(ThemeColors.whiteDim)
            .padding(.top, 6)

            // Pollutants
            if let aqi = vm.airQuality {
                VStack(alignment: .leading, spacing: 0) {
                    BlockLabel(text: "POLLUTANTS (μg/m³)")
                        .padding(.top, 16)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        pollutantRow("PM2.5", aqi.pm2_5)
                        pollutantRow("PM10", aqi.pm10)
                        pollutantRow("NO₂", aqi.nitrogen_dioxide)
                        pollutantRow("O₃", aqi.ozone)
                    }
                }
            }

            // Cloud Cover
            VStack(alignment: .leading, spacing: 0) {
                BlockLabel(text: "CLOUD COVER")
                    .padding(.top, 16)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(current.cloud_cover)")
                        .font(.system(size: 32, weight: .semibold, design: .default))
                        .foregroundColor(ThemeColors.white)
                    Text("%")
                        .font(.system(size: 16))
                        .foregroundColor(ThemeColors.whiteDim)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(ThemeColors.void4)
                            .frame(height: 4)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [ThemeColors.accent, ThemeColors.accentBright.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * Double(current.cloud_cover) / 100.0, height: 4)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .frame(height: 4)
                .padding(.top, 8)
            }
        }
        .panelStyle()
    }

    private func pollutantRow(_ name: String, _ value: Double) -> some View {
        HStack {
            Text(name)
                .foregroundColor(ThemeColors.whiteDim)
            Spacer()
            Text(String(format: "%.1f", value))
                .foregroundColor(ThemeColors.white)
        }
        .font(.system(size: 10, design: .monospaced))
    }
}

// MARK: - Wind Compass
struct WindCompass: View {
    let degrees: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(ThemeColors.accent.opacity(0.4), lineWidth: 1)

            // Direction labels
            Text("N").offset(y: -30)
            Text("S").offset(y: 30)
            Text("E").offset(x: 30)
            Text("W").offset(x: -30)

            // Needle
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [ThemeColors.accentBright, ThemeColors.whiteDim.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(width: 2, height: 32)
                .offset(y: -16)
                .rotationEffect(.degrees(degrees))

            // Center dot
            Circle()
                .fill(ThemeColors.accentBright)
                .frame(width: 6, height: 6)
        }
        .font(.system(size: 8, design: .monospaced))
        .foregroundColor(ThemeColors.whiteDim)
    }
}

// MARK: - UV Bar
struct UVBar: View {
    let value: Double

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow, .red, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 6)

                    Circle()
                        .fill(ThemeColors.white)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(ThemeColors.void0, lineWidth: 2))
                        .offset(x: geo.size.width * min(value / 12.0, 1.0) - 6)
                }
            }
            .frame(height: 12)

            HStack {
                Text("LOW").frame(maxWidth: .infinity, alignment: .leading)
                Text("MOD")
                Text("HIGH")
                Text("V.HIGH")
                Text("EXT").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 8, design: .monospaced))
            .tracking(1)
            .foregroundColor(ThemeColors.whiteDim)
        }
    }
}
