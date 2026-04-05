import SwiftUI

// MARK: - WMO Weather Codes
enum WeatherCode {
    static let descriptions: [Int: String] = [
        0: "Clear Sky", 1: "Mainly Clear", 2: "Partly Cloudy", 3: "Overcast",
        45: "Fog", 48: "Icy Fog",
        51: "Light Drizzle", 53: "Moderate Drizzle", 55: "Dense Drizzle",
        61: "Slight Rain", 63: "Moderate Rain", 65: "Heavy Rain",
        71: "Slight Snow", 73: "Moderate Snow", 75: "Heavy Snow", 77: "Snow Grains",
        80: "Slight Showers", 81: "Moderate Showers", 82: "Violent Showers",
        85: "Slight Snow Showers", 86: "Heavy Snow Showers",
        95: "Thunderstorm", 96: "Thunderstorm + Hail", 99: "Heavy Thunderstorm + Hail"
    ]

    static let icons: [Int: String] = [
        0:  "\u{2600}", 1: "\u{1F324}", 2: "\u{26C5}", 3: "\u{2601}",
        45: "\u{1F32B}", 48: "\u{1F32B}",
        51: "\u{1F326}", 53: "\u{1F326}", 55: "\u{1F327}",
        61: "\u{1F327}", 63: "\u{1F327}", 65: "\u{1F327}",
        71: "\u{1F328}", 73: "\u{1F328}", 75: "\u{2744}", 77: "\u{2744}",
        80: "\u{1F327}", 81: "\u{1F327}", 82: "\u{26C8}",
        85: "\u{1F328}", 86: "\u{2744}",
        95: "\u{26C8}", 96: "\u{26C8}", 99: "\u{26C8}"
    ]

    static let sfSymbols: [Int: String] = [
        0:  "sun.max.fill",        1: "sun.min.fill",          2: "cloud.sun.fill",
        3:  "cloud.fill",          45: "cloud.fog.fill",       48: "cloud.fog.fill",
        51: "cloud.drizzle.fill",  53: "cloud.drizzle.fill",   55: "cloud.rain.fill",
        61: "cloud.rain.fill",     63: "cloud.rain.fill",      65: "cloud.heavyrain.fill",
        71: "cloud.snow.fill",     73: "cloud.snow.fill",      75: "snowflake",
        77: "snowflake",           80: "cloud.rain.fill",      81: "cloud.rain.fill",
        82: "cloud.bolt.rain.fill",85: "cloud.snow.fill",      86: "snowflake",
        95: "cloud.bolt.fill",     96: "cloud.bolt.fill",      99: "cloud.bolt.fill"
    ]

    static func description(for code: Int) -> String { descriptions[code] ?? "Unknown" }
    static func icon(for code: Int) -> String { icons[code] ?? "\u{1F321}" }
    static func sfSymbol(for code: Int) -> String { sfSymbols[code] ?? "thermometer.medium" }
}

// MARK: - Unit Conversions
enum WeatherUnits {
    static func tempUnit(_ useCelsius: Bool) -> String { useCelsius ? "\u{00B0}C" : "\u{00B0}F" }
    static func metersToMiles(_ meters: Double) -> Double { meters / 1609.344 }

    static func formatTime(_ isoString: String) -> String {
        // Try ISO 8601 with fractional seconds
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate, .withFullTime, .withFractionalSeconds]
        if let date = iso.date(from: isoString) {
            let d = DateFormatter(); d.dateFormat = "h:mm a"
            return d.string(from: date)
        }
        // Try simple format
        let simple = DateFormatter(); simple.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = simple.date(from: isoString) {
            let d = DateFormatter(); d.dateFormat = "h:mm a"
            return d.string(from: date)
        }
        return isoString
    }

    static func daylightHours(sunrise: String, sunset: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        guard let rise = f.date(from: sunrise), let set = f.date(from: sunset) else { return "--" }
        return String(format: "%.1fh", set.timeIntervalSince(rise) / 3600)
    }
}

// MARK: - Wind
enum WindHelper {
    static func beaufort(_ mph: Double) -> String {
        let scale: [(Double, String)] = [
            (1, "0 · Calm"), (4, "1 · Light Air"), (8, "2 · Light Breeze"),
            (13, "3 · Gentle"), (19, "4 · Moderate"), (25, "5 · Fresh"),
            (32, "6 · Strong"), (39, "7 · Near Gale"), (47, "8 · Gale"),
            (55, "9 · Severe Gale"), (64, "10 · Storm"), (73, "11 · Violent Storm")
        ]
        for (threshold, label) in scale { if mph < threshold { return label } }
        return "12 · Hurricane"
    }

    static func degreeToCompass(_ degrees: Double) -> String {
        let directions = ["N","NNE","NE","ENE","E","ESE","SE","SSE",
                          "S","SSW","SW","WSW","W","WNW","NW","NNW"]
        return directions[Int(round(degrees / 22.5)) % 16]
    }
}

// MARK: - UV Index
enum UVHelper {
    static func label(_ uv: Double) -> String {
        if uv <= 2 { return "LOW" }
        if uv <= 5 { return "MODERATE" }
        if uv <= 7 { return "HIGH" }
        if uv <= 10 { return "VERY HIGH" }
        return "EXTREME"
    }
    static func color(_ uv: Double) -> Color {
        if uv <= 2 { return .green }
        if uv <= 5 { return .yellow }
        if uv <= 7 { return .orange }
        if uv <= 10 { return .red }
        return .purple
    }
}

// MARK: - Air Quality
enum AQIHelper {
    static func fromPM25(_ pm: Double) -> Int {
        if pm <= 12    { return Int(round((50.0 / 12.0)   * pm)) }
        if pm <= 35.4  { return Int(round(50  + (50.0  / 23.4)  * (pm - 12))) }
        if pm <= 55.4  { return Int(round(100 + (50.0  / 19.9)  * (pm - 35.4))) }
        if pm <= 150.4 { return Int(round(150 + (50.0  / 94.9)  * (pm - 55.4))) }
        return Int(round(200 + (100.0 / 149.9) * (pm - 150.4)))
    }

    static func category(_ aqi: Int) -> (label: String, color: Color) {
        if aqi <= 50  { return ("GOOD",                       .green) }
        if aqi <= 100 { return ("MODERATE",                   .yellow) }
        if aqi <= 150 { return ("UNHEALTHY FOR SENSITIVE",    .orange) }
        if aqi <= 200 { return ("UNHEALTHY",                  .red) }
        if aqi <= 300 { return ("VERY UNHEALTHY",             .purple) }
        return ("HAZARDOUS", Color(red: 0.49, green: 0.23, blue: 0.93))
    }
}

// MARK: - Pressure Trend Helper
enum PressureTrendHelper {
    /// Computes trend by comparing currentHour pressure vs 3 hours prior in the hourly array.
    static func compute(hourly: HourlyWeather) -> PressureTrend {
        let now = Calendar.current.component(.hour, from: Date())
        guard now < hourly.surface_pressure.count else { return .steady }
        let current = hourly.surface_pressure[now]
        let pastIndex = max(0, now - 3)
        let past = hourly.surface_pressure[pastIndex]
        let delta = current - past

        switch delta {
        case let d where d > 4:   return .rapidlyRising
        case let d where d > 1.5: return .rising
        case let d where d < -4:  return .rapidlyFalling
        case let d where d < -1.5: return .falling
        default:                  return .steady
        }
    }
}

// MARK: - Dew Point Comfort
enum DewPointHelper {
    static func comfort(_ dewF: Double) -> String {
        if dewF < 35  { return "VERY DRY" }
        if dewF < 45  { return "COMFORTABLE" }
        if dewF < 55  { return "PLEASANT" }
        if dewF < 65  { return "NOTICEABLE" }
        if dewF < 70  { return "HUMID" }
        return "OPPRESSIVE"
    }
}

// MARK: - Heat Index / Wind Chill label
enum FeelsLikeHelper {
    static func context(feelsLike: Double, actual: Double, useCelsius: Bool) -> String {
        let diff = feelsLike - actual
        let threshold = useCelsius ? 3.0 : 5.0
        if diff > threshold  { return "HOT FEEL" }
        if diff < -threshold { return "COLD FEEL" }
        return "NEAR ACTUAL"
    }
}

// MARK: - Alert Generation
enum AlertGenerator {
    static func generate(weather: CurrentWeather, daily: DailyWeather, aqi: AirQualityCurrent, useCelsius: Bool) -> [WeatherAlert] {
        var alerts: [WeatherAlert] = []
        let fl   = weather.apparent_temperature
        let g    = weather.wind_gusts_10m
        let unit = WeatherUnits.tempUnit(useCelsius)

        // Cold
        if fl <= 0 {
            alerts.append(WeatherAlert(level: .danger, icon: "🥶", title: "EXTREME COLD", message: "Feels \(Int(round(fl)))\(unit). Frostbite risk."))
        } else if fl <= 20 && !useCelsius {
            alerts.append(WeatherAlert(level: .warn, icon: "❄️", title: "COLD ADVISORY", message: "Feels \(Int(round(fl)))\(unit). Layer up."))
        }

        // Heat
        if fl >= 105 || (useCelsius && fl >= 40.5) {
            alerts.append(WeatherAlert(level: .danger, icon: "🔥", title: "EXTREME HEAT", message: "Feels \(Int(round(fl)))\(unit). Stay indoors."))
        } else if fl >= 90 || (useCelsius && fl >= 32.2) {
            alerts.append(WeatherAlert(level: .warn, icon: "☀️", title: "HEAT ADVISORY", message: "Feels \(Int(round(fl)))\(unit). Hydrate."))
        }

        // Wind
        if g >= 50 {
            alerts.append(WeatherAlert(level: .danger, icon: "💨", title: "HIGH WIND", message: "Gusts \(Int(round(g)))mph."))
        } else if g >= 35 {
            alerts.append(WeatherAlert(level: .warn, icon: "💨", title: "WIND ADVISORY", message: "Gusts \(Int(round(g)))mph."))
        }

        // UV
        if weather.uv_index >= 8 {
            alerts.append(WeatherAlert(level: .warn, icon: "☀️", title: "UV \(UVHelper.label(weather.uv_index))", message: "UV \(String(format: "%.1f", weather.uv_index)). Sunscreen required."))
        }

        // Visibility
        if weather.visibility < 1000 {
            alerts.append(WeatherAlert(level: .danger, icon: "🌫️", title: "DENSE FOG", message: "Vis \(String(format: "%.1f", WeatherUnits.metersToMiles(weather.visibility)))mi."))
        } else if weather.visibility < 3000 {
            alerts.append(WeatherAlert(level: .warn, icon: "🌫️", title: "LOW VIS", message: "Vis \(String(format: "%.1f", WeatherUnits.metersToMiles(weather.visibility)))mi."))
        }

        // AQI
        let aqiVal = AQIHelper.fromPM25(aqi.pm2_5)
        if aqiVal > 150 {
            alerts.append(WeatherAlert(level: .danger, icon: "😷", title: "AQI ALERT", message: "AQI \(aqiVal). Limit outdoor time."))
        } else if aqiVal > 100 {
            alerts.append(WeatherAlert(level: .warn, icon: "😷", title: "AQI NOTICE", message: "AQI \(aqiVal). Sensitive groups caution."))
        }

        // Heavy rain
        if weather.precipitation > 7 {
            alerts.append(WeatherAlert(level: .warn, icon: "🌧️", title: "HEAVY RAIN", message: "\(String(format: "%.1f", weather.precipitation))mm/hr."))
        }

        // Thunderstorm
        if [95, 96, 99].contains(weather.weather_code) {
            alerts.append(WeatherAlert(level: .danger, icon: "⛈️", title: "THUNDERSTORM", message: "Seek shelter."))
        }

        // Temp change tomorrow
        if daily.temperature_2m_max.count >= 2 {
            let diff = Int(round(daily.temperature_2m_max[1])) - Int(round(daily.temperature_2m_max[0]))
            if diff >= 15 {
                alerts.append(WeatherAlert(level: .info, icon: "⬆️", title: "TEMP SURGE", message: "↑\(diff)° warmer tomorrow."))
            } else if diff <= -15 {
                alerts.append(WeatherAlert(level: .info, icon: "⬇️", title: "TEMP DROP", message: "↓\(abs(diff))° cooler tomorrow."))
            }
        }

        return alerts
    }
}

// MARK: - Theme Colors
struct ThemeColors {
    static let void0        = Color(red: 0.031, green: 0.031, blue: 0.031)
    static let void2        = Color(red: 0.059, green: 0.059, blue: 0.059)
    static let void3        = Color(red: 0.086, green: 0.086, blue: 0.086)
    static let void4        = Color(red: 0.118, green: 0.118, blue: 0.118)
    static let accent       = Color(red: 0.486, green: 0.227, blue: 0.929)
    static let accentBright = Color(red: 0.659, green: 0.333, blue: 0.969)
    static let accentDim    = Color(red: 0.486, green: 0.227, blue: 0.929).opacity(0.15)
    static let white        = Color(red: 0.941, green: 0.941, blue: 0.941)
    static let whiteDim     = Color(red: 0.941, green: 0.941, blue: 0.941).opacity(0.5)
    static let panelBorder  = Color(red: 0.486, green: 0.227, blue: 0.929).opacity(0.2)
}

// MARK: - Weather Quotes
enum WeatherQuotes {
    static let all = [
        "The atmosphere owes you nothing. It gives you data.",
        "Every storm runs out of rain. Even in Ohio.",
        "Clear skies are just the void being honest.",
        "Pressure drops before the interesting stuff happens.",
        "Fog is the clouds getting comfortable at ground level.",
        "Snow depth: nature's storage metric.",
        "Soil temp — someone's gotta look out for the worms.",
        "Dew point above 65°F is nature's way of saying go inside.",
        "Wind chill is the wind's way of showing you who's boss.",
        "The barometer never lies. It just lets you draw your own conclusions."
    ]

    static var random: String { all.randomElement() ?? all[0] }
}
