import SwiftUI

struct CurrentConditionsView: View {
    @ObservedObject var vm: WeatherViewModel

    var body: some View {
        if let current = vm.currentWeather, let daily = vm.dailyWeather {
            #if os(iOS)
            VStack(spacing: 12) {
                heroBlock(current: current, daily: daily)
                windPressureBlock(current: current)
                aqiBlock(current: current)
            }
            #else
            // HStack natively equalises child heights; no GeometryReader/PreferenceKey needed.
            HStack(alignment: .top, spacing: 12) {
                heroBlock(current: current, daily: daily)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                windPressureBlock(current: current)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                aqiBlock(current: current)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            #endif
        }
    }

    // MARK: - Hero Block
    @ViewBuilder
    private func heroBlock(current: CurrentWeather, daily: DailyWeather) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            BlockLabel(text: "CURRENT CONDITIONS")

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(Int(round(current.temperature_2m)))")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(ThemeColors.white)
                Text(vm.tempUnit)
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(ThemeColors.accentBright)
                    .baselineOffset(36)
            }

            Text(WeatherCode.description(for: current.weather_code).uppercased())
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(ThemeColors.whiteDim)
                .padding(.top, 4)

            // Feels like + context
            let flContext = FeelsLikeHelper.context(
                feelsLike: current.apparent_temperature,
                actual: current.temperature_2m,
                useCelsius: vm.useCelsius
            )
            HStack(spacing: 0) {
                Text("FEELS LIKE ")
                    .foregroundColor(ThemeColors.whiteDim)
                Text("\(Int(round(current.apparent_temperature)))\(vm.tempUnit)")
                    .foregroundColor(ThemeColors.white)
                Text("  ·  \(flContext)")
                    .foregroundColor(ThemeColors.accentBright.opacity(0.6))
            }
            .font(.system(size: 10, design: .monospaced))
            .padding(.top, 8)

            // Dew point + comfort
            let dewComfort = DewPointHelper.comfort(current.dew_point_2m)
            HStack(spacing: 0) {
                Text("DEW POINT ")
                    .foregroundColor(ThemeColors.whiteDim)
                Text("\(Int(round(current.dew_point_2m)))\(vm.tempUnit)")
                    .foregroundColor(ThemeColors.white)
                Text("  ·  \(dewComfort)")
                    .foregroundColor(ThemeColors.whiteDim.opacity(0.6))
            }
            .font(.system(size: 10, design: .monospaced))
            .padding(.top, 4)

            // Sun row
            HStack(spacing: 8) {
                sunItem(icon: "☀", label: "SUNRISE",  value: WeatherUnits.formatTime(daily.sunrise[0]))
                sunItem(icon: "◑", label: "SUNSET",   value: WeatherUnits.formatTime(daily.sunset[0]))
                sunItem(icon: "◐", label: "DAYLIGHT", value: WeatherUnits.daylightHours(sunrise: daily.sunrise[0], sunset: daily.sunset[0]))
            }
            .padding(.top, 16)

            // Today range
            HStack(spacing: 0) {
                Text("TODAY  ")
                    .foregroundColor(ThemeColors.whiteDim)
                Text("H \(Int(round(daily.temperature_2m_max[0])))\(vm.tempUnit)")
                    .foregroundColor(ThemeColors.white)
                Text("  /  ")
                    .foregroundColor(ThemeColors.whiteDim)
                Text("L \(Int(round(daily.temperature_2m_min[0])))\(vm.tempUnit)")
                    .foregroundColor(ThemeColors.white)
            }
            .font(.system(size: 10, design: .monospaced))
            .padding(.top, 12)

            Spacer(minLength: 0)
        }
        .panelStyle()
        .overlay(
            Rectangle().fill(ThemeColors.accentBright).frame(width: 2),
            alignment: .leading
        )
    }

    private func sunItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 16))
            Text(label)
                .font(.system(size: 7, design: .monospaced))
                .tracking(2)
                .foregroundColor(ThemeColors.accentBright)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ThemeColors.white)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(ThemeColors.void3)
        .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Wind + Pressure Block
    @ViewBuilder
    private func windPressureBlock(current: CurrentWeather) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Wind
            VStack(alignment: .leading, spacing: 0) {
                BlockLabel(text: "WIND")
                HStack(spacing: 16) {
                    WindCompass(degrees: current.wind_direction_10m)
                        .frame(width: 76, height: 76)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(round(current.wind_speed_10m)))")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundColor(ThemeColors.white)
                            Text("mph")
                                .font(.system(size: 12))
                                .foregroundColor(ThemeColors.whiteDim)
                        }
                        windDetail("DIR",     WindHelper.degreeToCompass(current.wind_direction_10m))
                        windDetail("GUSTS",   "\(Int(round(current.wind_gusts_10m))) mph")
                        windDetail("SCALE",   WindHelper.beaufort(current.wind_speed_10m))
                    }
                }
            }

            // Pressure + trend
            VStack(alignment: .leading, spacing: 0) {
                BlockLabel(text: "PRESSURE")
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(round(current.surface_pressure)))")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(ThemeColors.white)
                    Text("hPa")
                        .font(.system(size: 11))
                        .foregroundColor(ThemeColors.whiteDim)
                    Text(vm.pressureTrend.symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(pressureTrendColor(vm.pressureTrend))
                }
                Text(vm.pressureTrend.rawValue)
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(pressureTrendColor(vm.pressureTrend))
                    .padding(.top, 2)
                Text(vm.pressureTrend.description)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(ThemeColors.whiteDim)
                    .padding(.top, 2)
            }

            // UV Index
            VStack(alignment: .leading, spacing: 0) {
                BlockLabel(text: "UV INDEX")
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", current.uv_index))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(ThemeColors.white)
                    Text(UVHelper.label(current.uv_index))
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(UVHelper.color(current.uv_index))
                }
                UVBar(value: current.uv_index)
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)
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
        .font(.system(size: 9, design: .monospaced))
    }

    private func pressureTrendColor(_ t: PressureTrend) -> Color {
        switch t {
        case .rapidlyRising:  return .green
        case .rising:         return Color(red: 0.5, green: 0.9, blue: 0.5)
        case .steady:         return ThemeColors.whiteDim
        case .falling:        return .orange
        case .rapidlyFalling: return .red
        }
    }

    // MARK: - AQI Block
    @ViewBuilder
    private func aqiBlock(current: CurrentWeather) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // AQI
            VStack(alignment: .leading, spacing: 0) {
                BlockLabel(text: "AIR QUALITY")
                let aqi = vm.aqiValue
                let cat = vm.aqiCategory

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(aqi)")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(cat.color)
                    Text(cat.label)
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(cat.color)
                }
                .padding(.top, 4)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(ThemeColors.void4).frame(height: 4)
                        Rectangle()
                            .fill(cat.color)
                            .frame(width: geo.size.width * min(Double(aqi) / 300.0, 1.0), height: 4)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .frame(height: 4)
                .padding(.top, 10)

                HStack {
                    Text("GOOD").frame(maxWidth: .infinity, alignment: .leading)
                    Text("MOD")
                    Text("USG")
                    Text("HAZ").frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(ThemeColors.whiteDim)
                .padding(.top, 4)
            }

            // Pollutants
            if let aq = vm.airQuality {
                VStack(alignment: .leading, spacing: 0) {
                    BlockLabel(text: "POLLUTANTS (μg/m³)")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        pollutantRow("PM2.5", aq.pm2_5)
                        pollutantRow("PM10",  aq.pm10)
                        pollutantRow("NO₂",   aq.nitrogen_dioxide)
                        pollutantRow("O₃",    aq.ozone)
                    }
                }
            }

            // Cloud Cover
            VStack(alignment: .leading, spacing: 0) {
                BlockLabel(text: "CLOUD COVER")
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(current.cloud_cover)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(ThemeColors.white)
                    Text("%")
                        .font(.system(size: 14))
                        .foregroundColor(ThemeColors.whiteDim)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(ThemeColors.void4).frame(height: 4)
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [ThemeColors.accent, ThemeColors.accentBright.opacity(0.4)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * Double(current.cloud_cover) / 100.0, height: 4)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .frame(height: 4)
                .padding(.top, 8)
            }

            Spacer(minLength: 0)
        }
        .panelStyle()
    }

    private func pollutantRow(_ name: String, _ value: Double) -> some View {
        HStack {
            Text(name).foregroundColor(ThemeColors.whiteDim)
            Spacer()
            Text(String(format: "%.1f", value)).foregroundColor(ThemeColors.white)
        }
        .font(.system(size: 9, design: .monospaced))
        .padding(6)
        .background(ThemeColors.void3)
        .overlay(Rectangle().stroke(ThemeColors.accent.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Wind Compass
struct WindCompass: View {
    let degrees: Double

    var body: some View {
        ZStack {
            Circle().stroke(ThemeColors.accent.opacity(0.3), lineWidth: 1)
            Circle().stroke(ThemeColors.accent.opacity(0.1), lineWidth: 0.5).padding(8)

            ForEach(["N","E","S","W"].indices, id: \.self) { i in
                let angle = Double(i) * 90
                let rad   = angle * .pi / 180
                let r     = 26.0
                Text(["N","E","S","W"][i])
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(i == 0 ? ThemeColors.accentBright : ThemeColors.whiteDim)
                    .offset(x: CGFloat(sin(rad) * r), y: CGFloat(-cos(rad) * r))
            }

            // Needle
            Rectangle()
                .fill(LinearGradient(
                    colors: [ThemeColors.accentBright, ThemeColors.accent.opacity(0.3)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 2, height: 26)
                .offset(y: -13)
                .rotationEffect(.degrees(degrees))

            Circle().fill(ThemeColors.accentBright).frame(width: 5, height: 5)
        }
    }
}

// MARK: - UV Bar
struct UVBar: View {
    let value: Double

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [.green, .yellow, .orange, .red, .purple],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(height: 6)

                    Circle()
                        .fill(ThemeColors.white)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(ThemeColors.void0, lineWidth: 2))
                        .offset(x: geo.size.width * min(value / 12.0, 1.0) - 5.5)
                }
            }
            .frame(height: 11)

            HStack {
                Text("LOW").frame(maxWidth: .infinity, alignment: .leading)
                Text("MOD")
                Text("HIGH")
                Text("EXT").frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 7, design: .monospaced))
            .foregroundColor(ThemeColors.whiteDim)
        }
    }
}
