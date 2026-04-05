import Foundation

// MARK: - Open-Meteo API Response
struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
    let hourly: HourlyWeather
}

struct CurrentWeather: Codable {
    let temperature_2m: Double
    let relative_humidity_2m: Int
    let apparent_temperature: Double
    let weather_code: Int
    let surface_pressure: Double
    let wind_speed_10m: Double
    let wind_direction_10m: Double
    let wind_gusts_10m: Double
    let precipitation: Double
    let cloud_cover: Int
    let visibility: Double
    let uv_index: Double
    let dew_point_2m: Double
}

struct DailyWeather: Codable {
    let time: [String]
    let weather_code: [Int]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let precipitation_probability_max: [Int]
    let sunrise: [String]
    let sunset: [String]
    let uv_index_max: [Double]
    let et0_fao_evapotranspiration: [Double]
}

struct HourlyWeather: Codable {
    let time: [String]
    let temperature_2m: [Double]
    let weather_code: [Int]
    let precipitation_probability: [Int]
    let wind_speed_10m: [Double]
    let snow_depth: [Double]
    let soil_temperature_0cm: [Double]
}

// MARK: - Air Quality API Response
struct AirQualityResponse: Codable {
    let current: AirQualityCurrent
}

struct AirQualityCurrent: Codable {
    let pm10: Double
    let pm2_5: Double
    let nitrogen_dioxide: Double
    let ozone: Double
}

// MARK: - RainViewer API Response
struct RainViewerResponse: Codable {
    let radar: RainViewerRadar
}

struct RainViewerRadar: Codable {
    let past: [RadarFrame]
    let nowcast: [RadarFrame]?
}

struct RadarFrame: Codable, Identifiable {
    let time: Int
    let path: String
    var id: Int { time }
}

// MARK: - App Models

struct WeatherAlert: Identifiable {
    let id = UUID()
    let level: AlertLevel
    let icon: String
    let title: String
    let message: String

    enum AlertLevel {
        case info, warn, danger

        var color: String {
            switch self {
            case .info: return "purple"
            case .warn: return "yellow"
            case .danger: return "red"
            }
        }
    }
}

struct HourlyItem: Identifiable {
    let id = UUID()
    let time: String
    let icon: String
    let temp: Int
    let precipChance: Int
    let windSpeed: Int
    let isNow: Bool
}

struct ForecastDay: Identifiable {
    let id = UUID()
    let index: Int
    let dayName: String
    let icon: String
    let high: Int
    let low: Int
    let precipChance: Int
    let uvMax: Double
    let sunrise: String
    let sunset: String
    let condition: String
    let isToday: Bool
    let dateString: String
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let text: String
    let timestamp = Date()

    enum ChatRole {
        case user, assistant
    }
}

// MARK: - App Configuration
struct AppConfig: Codable {
    var useCelsius: Bool = false
    var accentColor: String = "#7c3aed"
    var accentBright: String = "#a855f7"
    var voidColor: String = "#080808"
    var radarProvider: String = "rainviewer"
    var showConditions: Bool = true
    var showAlerts: Bool = true
    var showMetrics: Bool = true
    var showHourly: Bool = true
    var showRadar: Bool = true
    var showAI: Bool = true

    static let `default` = AppConfig()
}
