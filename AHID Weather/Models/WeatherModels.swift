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
    let apparent_temperature: [Double]
    let weather_code: [Int]
    let precipitation_probability: [Int]
    let wind_speed_10m: [Double]
    let wind_direction_10m: [Double]
    let relative_humidity_2m: [Int]
    let snow_depth: [Double]
    let soil_temperature_0cm: [Double]
    let surface_pressure: [Double]
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

// MARK: - Radar Layer
enum RadarLayer: String, CaseIterable, Identifiable {
    case precipitation = "precipitation_new"
    case temperature   = "temp_new"
    case wind          = "wind_new"
    case clouds        = "clouds_new"
    case pressure      = "pressure_new"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .precipitation: return "PRECIP"
        case .temperature:   return "TEMP"
        case .wind:          return "WIND"
        case .clouds:        return "CLOUDS"
        case .pressure:      return "PRESSURE"
        }
    }

    var icon: String {
        switch self {
        case .precipitation: return "🌧"
        case .temperature:   return "🌡"
        case .wind:          return "💨"
        case .clouds:        return "☁"
        case .pressure:      return "◎"
        }
    }

    /// PRECIP uses RainViewer tiles; all others require an OWM key
    var usesRainViewer: Bool { self == .precipitation }

    func owmTileTemplate(key: String) -> String {
        "https://tile.openweathermap.org/map/\(rawValue)/{z}/{x}/{y}.png?appid=\(key)"
    }
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

        var colorName: String {
            switch self {
            case .info:   return "purple"
            case .warn:   return "yellow"
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
    let feelsLike: Int
    let precipChance: Int
    let windSpeed: Int
    let windDirection: Int
    let humidity: Int
    let conditionCode: Int
    let isNow: Bool

    var conditionDesc: String { WeatherCode.description(for: conditionCode) }
    var windCompass: String { WindHelper.degreeToCompass(Double(windDirection)) }
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

    enum ChatRole { case user, assistant }
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

// MARK: - Pressure Trend
enum PressureTrend: String {
    case rising       = "RISING"
    case falling      = "FALLING"
    case steady       = "STEADY"
    case rapidlyRising  = "RAPIDLY RISING"
    case rapidlyFalling = "RAPIDLY FALLING"

    var symbol: String {
        switch self {
        case .rising:         return "↑"
        case .falling:        return "↓"
        case .steady:         return "→"
        case .rapidlyRising:  return "⬆"
        case .rapidlyFalling: return "⬇"
        }
    }

    var description: String {
        switch self {
        case .rising:         return "Improving conditions likely"
        case .falling:        return "Deteriorating conditions possible"
        case .steady:         return "Conditions stable"
        case .rapidlyRising:  return "Marked clearing expected"
        case .rapidlyFalling: return "Storm system approaching"
        }
    }
}

// MARK: - App Error
enum AppError: LocalizedError, Identifiable {
    // Weather data
    case wx001_invalidURL
    case wx002_networkTimeout
    case wx003_httpError(Int, String)
    case wx004_decodeFailed(String)
    case wx005_noData

    // Location
    case loc001_denied
    case loc002_timeout
    case loc003_unavailable
    case loc004_geocodeFailed

    // AI
    case ai001_noKeyConfigured
    case ai002_allProvidersFailed
    case ai003_rateLimited(String)
    case ai004_invalidKey(String)
    case ai005_httpError(Int, String)

    // Key test
    case key001_invalidKey(String)
    case key002_rateLimited(String)
    case key003_networkError(String)
    case key004_httpError(Int, String)

    var id: String { code }

    var code: String {
        switch self {
        case .wx001_invalidURL:        return "WX-001"
        case .wx002_networkTimeout:    return "WX-002"
        case .wx003_httpError:         return "WX-003"
        case .wx004_decodeFailed:      return "WX-004"
        case .wx005_noData:            return "WX-005"
        case .loc001_denied:           return "LOC-001"
        case .loc002_timeout:          return "LOC-002"
        case .loc003_unavailable:      return "LOC-003"
        case .loc004_geocodeFailed:    return "LOC-004"
        case .ai001_noKeyConfigured:   return "AI-001"
        case .ai002_allProvidersFailed:return "AI-002"
        case .ai003_rateLimited:       return "AI-003"
        case .ai004_invalidKey:        return "AI-004"
        case .ai005_httpError:         return "AI-005"
        case .key001_invalidKey:       return "KEY-001"
        case .key002_rateLimited:      return "KEY-002"
        case .key003_networkError:     return "KEY-003"
        case .key004_httpError:        return "KEY-004"
        }
    }

    var errorDescription: String? {
        switch self {
        case .wx001_invalidURL:
            return "[\(code)] Malformed API request URL. This is a bug — please report it."
        case .wx002_networkTimeout:
            return "[\(code)] Weather API timed out after 10s. Check your connection."
        case .wx003_httpError(let status, let provider):
            return "[\(code)] \(provider) returned HTTP \(status). Service may be degraded."
        case .wx004_decodeFailed(let detail):
            return "[\(code)] API response schema changed: \(detail). Update may be needed."
        case .wx005_noData:
            return "[\(code)] Weather API returned an empty response."
        case .loc001_denied:
            return "[\(code)] Location access denied. Enable in System Preferences → Privacy → Location Services."
        case .loc002_timeout:
            return "[\(code)] GPS acquisition timed out after 3s. Using fallback coordinates."
        case .loc003_unavailable:
            return "[\(code)] Location services unavailable. Using fallback coordinates."
        case .loc004_geocodeFailed:
            return "[\(code)] Reverse geocoding failed. Coordinates are still valid."
        case .ai001_noKeyConfigured:
            return "[\(code)] No AI provider key configured. Add one in Settings → API Keys."
        case .ai002_allProvidersFailed:
            return "[\(code)] All configured AI providers failed. Using local fallback response."
        case .ai003_rateLimited(let provider):
            return "[\(code)] \(provider) rate limit exceeded. Using local fallback."
        case .ai004_invalidKey(let provider):
            return "[\(code)] \(provider) rejected the API key (401). Verify it in Settings → API Keys."
        case .ai005_httpError(let status, let provider):
            return "[\(code)] \(provider) returned HTTP \(status)."
        case .key001_invalidKey(let provider):
            return "[\(code)] \(provider) key is invalid or expired (401/403)."
        case .key002_rateLimited(let provider):
            return "[\(code)] \(provider) returned 429 during key test. Key is valid but rate-limited."
        case .key003_networkError(let detail):
            return "[\(code)] Network error during key test: \(detail)"
        case .key004_httpError(let status, let provider):
            return "[\(code)] \(provider) returned unexpected HTTP \(status) during key test."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .wx002_networkTimeout, .wx003_httpError:
            return "Try refreshing in a moment."
        case .loc001_denied:
            return "Open System Preferences → Security & Privacy → Privacy → Location Services."
        case .ai001_noKeyConfigured:
            return "Open Settings (⌘,) → API Keys and add an Anthropic, Gemini, or OpenAI key."
        case .key001_invalidKey(let provider):
            return "Log in to the \(provider) developer portal and verify or regenerate your key."
        default:
            return nil
        }
    }
}
