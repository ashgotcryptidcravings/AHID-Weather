import SwiftUI
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    // MARK: - Published State
    @Published var currentWeather: CurrentWeather?
    @Published var dailyWeather: DailyWeather?
    @Published var hourlyWeather: HourlyWeather?
    @Published var airQuality: AirQualityCurrent?

    @Published var alerts: [WeatherAlert] = []
    @Published var hourlyItems: [HourlyItem] = []
    @Published var forecastDays: [ForecastDay] = []
    @Published var chatMessages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Ask me anything about the current weather conditions.")
    ]

    @Published var isLoading: Bool = true
    @Published var loadingMessage: String = "REQUESTING LOCATION"
    @Published var errorMessage: String?
    @Published var lastUpdated: String = "—"
    @Published var quote: String = WeatherQuotes.random
    @Published var isChatLoading: Bool = false

    // Selected forecast day for detail view
    @Published var selectedForecastIndex: Int? = nil
    @Published var forecastAISummary: String?
    @Published var isForecastAILoading: Bool = false

    // MARK: - Config
    @AppStorage("useCelsius") var useCelsius: Bool = false
    @AppStorage("showConditions") var showConditions: Bool = true
    @AppStorage("showAlerts") var showAlerts: Bool = true
    @AppStorage("showMetrics") var showMetrics: Bool = true
    @AppStorage("showHourly") var showHourly: Bool = true
    @AppStorage("showRadar") var showRadar: Bool = true
    @AppStorage("showAI") var showAI: Bool = true

    // API Keys stored in UserDefaults (encrypted in HTML version, plain here for simplicity)
    @AppStorage("apiKey_anthropic") var anthropicKey: String = ""
    @AppStorage("apiKey_gemini") var geminiKey: String = ""
    @AppStorage("apiKey_openai") var openaiKey: String = ""
    @AppStorage("apiKey_owm") var owmKey: String = ""

    // MARK: - Services
    let locationService = LocationService()
    private let weatherService = WeatherService()
    private let aiService = AIService()

    // MARK: - Computed
    var tempUnit: String { WeatherUnits.tempUnit(useCelsius) }

    var coordDisplay: String {
        let lat = locationService.latitude
        let lon = locationService.longitude
        let latDir = lat >= 0 ? "N" : "S"
        let lonDir = lon < 0 ? "W" : "E"
        return String(format: "%.3f%@ %.3f%@", abs(lat), latDir, abs(lon), lonDir)
    }

    var aqiValue: Int {
        AQIHelper.fromPM25(airQuality?.pm2_5 ?? 0)
    }

    var aqiCategory: (label: String, color: Color) {
        AQIHelper.category(aqiValue)
    }

    // MARK: - Initialization
    func start() async {
        loadingMessage = "REQUESTING LOCATION"
        isLoading = true

        let gotLocation = await locationService.acquireLocation()
        if !gotLocation {
            loadingMessage = "DEFAULT · TOLEDO"
        }

        await syncAIKeys()
        await fetchWeatherData(force: true)

        isLoading = false

        // Background refresh every 10 minutes
        startBackgroundRefresh()
    }

    // MARK: - Data Fetching
    func fetchWeatherData(force: Bool = false) async {
        loadingMessage = "FETCHING DATA"
        errorMessage = nil

        do {
            let (weather, aqi) = try await weatherService.fetchWeather(
                lat: locationService.latitude,
                lon: locationService.longitude,
                useCelsius: useCelsius,
                force: force
            )

            currentWeather = weather.current
            dailyWeather = weather.daily
            hourlyWeather = weather.hourly
            airQuality = aqi.current

            // Process derived data
            processAlerts()
            processHourly()
            processForecast()

            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            lastUpdated = "UPDATED \(formatter.string(from: Date()))"
            quote = WeatherQuotes.random

        } catch {
            errorMessage = error.localizedDescription
            print("[AHID] Weather fetch error: \(error)")
        }
    }

    func refresh() async {
        await fetchWeatherData(force: true)
    }

    // MARK: - Processing
    private func processAlerts() {
        guard let current = currentWeather, let daily = dailyWeather, let aqi = airQuality else { return }
        alerts = AlertGenerator.generate(weather: current, daily: daily, aqi: aqi, useCelsius: useCelsius)
    }

    private func processHourly() {
        guard let hourly = hourlyWeather else { return }
        let currentHour = Calendar.current.component(.hour, from: Date())
        var items: [HourlyItem] = []

        for offset in 0..<24 {
            let idx = currentHour + offset
            guard idx < hourly.time.count else { break }

            let timeStr: String
            if offset == 0 {
                timeStr = "NOW"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
                if let date = formatter.date(from: hourly.time[idx]) {
                    let display = DateFormatter()
                    display.dateFormat = "ha"
                    timeStr = display.string(from: date).uppercased()
                } else {
                    timeStr = "--"
                }
            }

            items.append(HourlyItem(
                time: timeStr,
                icon: WeatherCode.icon(for: hourly.weather_code[idx]),
                temp: Int(round(hourly.temperature_2m[idx])),
                precipChance: hourly.precipitation_probability[idx],
                windSpeed: Int(round(hourly.wind_speed_10m[idx])),
                isNow: offset == 0
            ))
        }
        hourlyItems = items
    }

    private func processForecast() {
        guard let daily = dailyWeather else { return }
        var days: [ForecastDay] = []

        for i in 0..<min(7, daily.time.count) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.date(from: daily.time[i]) ?? Date()

            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            let name = i == 0 ? "TODAY" : dayFormatter.string(from: date).uppercased()

            let longFormatter = DateFormatter()
            longFormatter.dateStyle = .long
            let dateString = longFormatter.string(from: date).uppercased()

            days.append(ForecastDay(
                index: i,
                dayName: name,
                icon: WeatherCode.icon(for: daily.weather_code[i]),
                high: Int(round(daily.temperature_2m_max[i])),
                low: Int(round(daily.temperature_2m_min[i])),
                precipChance: daily.precipitation_probability_max[i],
                uvMax: daily.uv_index_max[i],
                sunrise: WeatherUnits.formatTime(daily.sunrise[i]),
                sunset: WeatherUnits.formatTime(daily.sunset[i]),
                condition: WeatherCode.description(for: daily.weather_code[i]),
                isToday: i == 0,
                dateString: dateString
            ))
        }
        forecastDays = days
    }

    // MARK: - Forecast Detail
    func selectForecastDay(_ index: Int) {
        if selectedForecastIndex == index {
            selectedForecastIndex = nil
            forecastAISummary = nil
            return
        }
        selectedForecastIndex = index
        forecastAISummary = nil
        Task { await fetchForecastAI(index: index) }
    }

    private func fetchForecastAI(index: Int) async {
        guard index < forecastDays.count else { return }
        let day = forecastDays[index]
        isForecastAILoading = true

        let system = "Weather analyst. 2 sentences, practical. Under 40 words. No markdown. No emoji."
        let prompt = "\(locationService.city) forecast for \(day.dateString): \(day.condition), \(day.high)/\(day.low)\(tempUnit), \(day.precipChance)% precip, UV \(String(format: "%.1f", day.uvMax))"

        let result = await aiService.chat(system: system, message: prompt)

        if selectedForecastIndex == index {
            if let text = result {
                forecastAISummary = text
            } else {
                forecastAISummary = localForecastSummary(day)
            }
            isForecastAILoading = false
        }
    }

    private func localForecastSummary(_ day: ForecastDay) -> String {
        var s = ""
        if day.high >= 85 { s += "Hot, \(day.high)\(tempUnit). " }
        else if day.high >= 70 { s += "\(day.high)\(tempUnit). " }
        else if day.high >= 50 { s += "Cool, \(day.high)\(tempUnit). " }
        else { s += "Cold, \(day.high)\(tempUnit). " }
        s += day.condition + ". "
        if day.precipChance > 40 { s += "\(day.precipChance)% rain. " }
        if day.uvMax > 5 { s += "UV \(String(format: "%.1f", day.uvMax))." }
        return s
    }

    // MARK: - AI Chat
    func sendChatMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        chatMessages.append(ChatMessage(role: .user, text: trimmed))
        isChatLoading = true

        let context = buildWeatherContext()
        let system = "AHID Weather assistant. Calm, direct, data-driven. Under 60 words. No markdown. No emoji.\n\n\(context)"

        let result = await aiService.chat(system: system, message: trimmed)
        let response = result ?? localChatResponse(trimmed)

        chatMessages.append(ChatMessage(role: .assistant, text: response))
        isChatLoading = false
    }

    private func buildWeatherContext() -> String {
        guard let c = currentWeather, let d = dailyWeather else { return "" }
        let u = tempUnit
        return """
        Location: \(locationService.city)
        Now: \(Int(round(c.temperature_2m)))\(u) (feels \(Int(round(c.apparent_temperature)))\(u)), \(WeatherCode.description(for: c.weather_code))
        Humidity \(c.relative_humidity_2m)% | Cloud \(c.cloud_cover)% | Wind \(Int(round(c.wind_speed_10m)))mph \(WindHelper.degreeToCompass(c.wind_direction_10m)) gusts \(Int(round(c.wind_gusts_10m)))
        UV \(String(format: "%.1f", c.uv_index)) | Vis \(String(format: "%.1f", WeatherUnits.metersToMiles(c.visibility)))mi | Precip \(String(format: "%.1f", c.precipitation))mm/hr | AQI \(aqiValue)
        Today H\(Int(round(d.temperature_2m_max[0])))\(u)/L\(Int(round(d.temperature_2m_min[0])))\(u) \(d.precipitation_probability_max[0])% precip
        """
    }

    private func localChatResponse(_ query: String) -> String {
        guard let c = currentWeather, let d = dailyWeather else { return "Weather data loading..." }
        let t = Int(round(c.temperature_2m))
        let fl = Int(round(c.apparent_temperature))
        let condition = WeatherCode.description(for: c.weather_code).lowercased()
        let u = tempUnit
        let wind = Int(round(c.wind_speed_10m))
        let uv = c.uv_index
        let pp = d.precipitation_probability_max.first ?? 0
        let hi = Int(round(d.temperature_2m_max[0]))
        let lo = Int(round(d.temperature_2m_min[0]))
        let q = query.lowercased()

        if q.contains("wear") || q.contains("dress") || q.contains("outfit") {
            if t < 30 { return "\(t)\(u) (feels \(fl)\(u)). Heavy coat, layers, gloves." }
            if t < 50 { return "\(t)\(u). Jacket.\(wind > 15 ? " Windy." : "")" }
            if t < 70 { return "\(t)\(u), \(condition). Light layer.\(pp > 40 ? " Umbrella." : "")" }
            if t < 85 { return "\(t)\(u). T-shirt.\(uv > 5 ? " Sunscreen." : "")" }
            return "\(t)\(u). Hot. Stay light, hydrate."
        }
        if q.contains("umbrella") || q.contains("rain") {
            if c.precipitation > 0 { return "Raining now (\(String(format: "%.1f", c.precipitation))mm/hr). Yes." }
            return pp > 50 ? "\(pp)% chance. Bring one." : pp > 20 ? "\(pp)%. Your call." : "\(pp)%. You're fine."
        }
        if q.contains("uv") || q.contains("sun") {
            return "UV \(String(format: "%.1f", uv)) — \(UVHelper.label(uv).lowercased()).\(uv > 5 ? " Sunscreen." : "")"
        }
        if q.contains("wind") {
            return "\(wind)mph \(WindHelper.degreeToCompass(c.wind_direction_10m)), gusts \(Int(round(c.wind_gusts_10m))). \(WindHelper.beaufort(c.wind_speed_10m))."
        }

        return "\(locationService.city): \(t)\(u) (feels \(fl)\(u)), \(condition). Wind \(wind)mph. \(lo)–\(hi)\(u). \(pp)% rain."
    }

    // MARK: - AI Key Sync
    func syncAIKeys() async {
        await aiService.setKeys(
            anthropic: anthropicKey.isEmpty ? nil : anthropicKey,
            gemini: geminiKey.isEmpty ? nil : geminiKey,
            openai: openaiKey.isEmpty ? nil : openaiKey
        )
    }

    // MARK: - Background Refresh
    private func startBackgroundRefresh() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchWeatherData()
            }
        }
    }
}
