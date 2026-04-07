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
    @Published var pressureTrend: PressureTrend = .steady
    @Published var chatMessages: [ChatMessage] = []

    @Published var isLoading: Bool = true
    @Published var loadingMessage: String = "REQUESTING LOCATION"
    @Published var errorMessage: String?
    @Published var lastUpdated: String = "—"
    @Published var quote: String = WeatherQuotes.random
    @Published var isChatLoading: Bool = false

    @Published var selectedForecastIndex: Int? = nil
    @Published var forecastAISummary: String?
    @Published var isForecastAILoading: Bool = false

    // MARK: - Config
    @AppStorage("useCelsius")          var useCelsius: Bool = false
    @AppStorage("showConditions")      var showConditions: Bool = true
    @AppStorage("showAlerts")          var showAlerts: Bool = true
    @AppStorage("showMetrics")         var showMetrics: Bool = true
    @AppStorage("showHourly")          var showHourly: Bool = true
    @AppStorage("showRadar")           var showRadar: Bool = true
    @AppStorage("showAI")              var showAI: Bool = true
    @AppStorage("autoRefreshEnabled")  var autoRefreshEnabled: Bool = true
    @AppStorage("refreshIntervalMin")  var refreshIntervalMin: Int = 10
    @AppStorage("aiTimeoutSeconds")    var aiTimeoutSeconds: Double = 12
    @AppStorage("aiMaxTokens")         var aiMaxTokens: Int = 300
    @AppStorage("verboseLogging")      var verboseLogging: Bool = false
    @AppStorage("errorSoundEnabled")   var errorSoundEnabled: Bool = true
    @AppStorage("errorNotifEnabled")   var errorNotifEnabled: Bool = true

    @AppStorage("apiKey_anthropic") var anthropicKey: String = ""
    @AppStorage("apiKey_gemini")    var geminiKey: String = ""
    @AppStorage("apiKey_openai")    var openaiKey: String = ""
    @AppStorage("apiKey_owm")       var owmKey: String = ""

    // MARK: - Services
    let locationService = LocationService()
    let weatherService  = WeatherService()
    let aiService       = AIService()

    // MARK: - Computed
    var tempUnit: String { WeatherUnits.tempUnit(useCelsius) }

    var coordDisplay: String {
        let lat = locationService.latitude
        let lon = locationService.longitude
        return String(format: "%.3f%@ %.3f%@",
                      abs(lat), lat >= 0 ? "N" : "S",
                      abs(lon), lon < 0  ? "W" : "E")
    }

    var aqiValue: Int { AQIHelper.fromPM25(airQuality?.pm2_5 ?? 0) }
    var aqiCategory: (label: String, color: Color) { AQIHelper.category(aqiValue) }

    // MARK: - Lifecycle
    func start() async {
        loadingMessage = "REQUESTING LOCATION"
        isLoading = true

        let gotLocation = await locationService.acquireLocation()
        if !gotLocation { loadingMessage = "DEFAULT · TOLEDO" }

        await ErrorNotificationService.shared.requestPermission()
        await syncAIKeys()
        await fetchWeatherData(force: true)

        isLoading = false
        startBackgroundRefresh()
        observeClearChat()
    }

    private func observeClearChat() {
            NotificationCenter.default.addObserver(
                forName: Notification.Name("AHID.clearChat"),
                object: nil, queue: .main
            ) { _ in
                // Capture weak self directly inside the Task here as well
                Task { @MainActor [weak self] in
                    self?.chatMessages = []
                }
            }
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
            dailyWeather   = weather.daily
            hourlyWeather  = weather.hourly
            airQuality     = aqi.current

            processAlerts()
            processHourly()
            processForecast()
            computePressureTrend()

            let f = DateFormatter(); f.dateFormat = "h:mm a"
            lastUpdated = "UPDATED \(f.string(from: Date()))"
            quote = WeatherQuotes.random

        } catch let err as AppError {
            errorMessage = err.localizedDescription
            print("[AHID] \(err.code): \(err.localizedDescription )")
            ErrorNotificationService.shared.handle(err, soundEnabled: errorSoundEnabled, notifEnabled: errorNotifEnabled)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async { await fetchWeatherData(force: true) }

    // MARK: - Processing
    private func processAlerts() {
        guard let c = currentWeather, let d = dailyWeather, let a = airQuality else { return }
        alerts = AlertGenerator.generate(weather: c, daily: d, aqi: a, useCelsius: useCelsius)
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
                let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
                if let date = fmt.date(from: hourly.time[idx]) {
                    let disp = DateFormatter(); disp.dateFormat = "ha"
                    timeStr = disp.string(from: date).uppercased()
                } else {
                    timeStr = "--"
                }
            }

            let feelsLike = idx < hourly.apparent_temperature.count
                ? Int(round(hourly.apparent_temperature[idx])) : 0
            let humidity = idx < hourly.relative_humidity_2m.count
                ? hourly.relative_humidity_2m[idx] : 0
            let windDir = idx < hourly.wind_direction_10m.count
                ? Int(round(hourly.wind_direction_10m[idx])) : 0
            let condCode = idx < hourly.weather_code.count
                ? hourly.weather_code[idx] : 0

            items.append(HourlyItem(
                time:          timeStr,
                icon:          WeatherCode.icon(for: condCode),
                temp:          Int(round(hourly.temperature_2m[idx])),
                feelsLike:     feelsLike,
                precipChance:  hourly.precipitation_probability[idx],
                windSpeed:     Int(round(hourly.wind_speed_10m[idx])),
                windDirection: windDir,
                humidity:      humidity,
                conditionCode: condCode,
                isNow:         offset == 0
            ))
        }
        hourlyItems = items
    }

    private func processForecast() {
        guard let daily = dailyWeather else { return }
        var days: [ForecastDay] = []

        for i in 0..<min(7, daily.time.count) {
            let dateFmt = DateFormatter(); dateFmt.dateFormat = "yyyy-MM-dd"
            let date = dateFmt.date(from: daily.time[i]) ?? Date()

            let dayFmt = DateFormatter(); dayFmt.dateFormat = "EEE"
            let dayName = i == 0 ? "TODAY" : dayFmt.string(from: date).uppercased()

            let longFmt = DateFormatter(); longFmt.dateStyle = .long
            let dateString = longFmt.string(from: date).uppercased()

            days.append(ForecastDay(
                index:       i,
                dayName:     dayName,
                icon:        WeatherCode.icon(for: daily.weather_code[i]),
                high:        Int(round(daily.temperature_2m_max[i])),
                low:         Int(round(daily.temperature_2m_min[i])),
                precipChance: daily.precipitation_probability_max[i],
                uvMax:       daily.uv_index_max[i],
                sunrise:     WeatherUnits.formatTime(daily.sunrise[i]),
                sunset:      WeatherUnits.formatTime(daily.sunset[i]),
                condition:   WeatherCode.description(for: daily.weather_code[i]),
                isToday:     i == 0,
                dateString:  dateString
            ))
        }
        forecastDays = days
    }

    private func computePressureTrend() {
        guard let hourly = hourlyWeather else { return }
        pressureTrend = PressureTrendHelper.compute(hourly: hourly)
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

        await syncAIKeys()
        let result = await aiService.chat(system: system, message: prompt)

        if selectedForecastIndex == index {
            if let text = result {
                forecastAISummary = text
            } else {
                let hasKeys = !anthropicKey.isEmpty || !geminiKey.isEmpty || !openaiKey.isEmpty
                forecastAISummary = hasKeys ? "[AI-002] All providers failed." : "[AI-001] No API key configured."
            }
            isForecastAILoading = false
        }
    }

    // MARK: - AI Chat
    func sendChatMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        chatMessages.append(ChatMessage(role: .user, text: trimmed))
        isChatLoading = true

        await syncAIKeys()

        let context = buildWeatherContext()
        let system = "AHID Weather assistant. Calm, direct, data-driven. Under 60 words. No markdown. No emoji.\n\n\(context)"

        let result = await aiService.chat(system: system, message: trimmed)
        if let text = result {
            chatMessages.append(ChatMessage(role: .assistant, text: text))
        } else {
            let hasKeys = !anthropicKey.isEmpty || !geminiKey.isEmpty || !openaiKey.isEmpty
            let errorCode = hasKeys ? "AI-002" : "AI-001"
            let errorMsg  = hasKeys
                ? "[AI-002] All configured providers failed. Check your keys or network."
                : "[AI-001] No AI provider key configured. Add a key in Settings → API Keys."
            chatMessages.append(ChatMessage(role: .assistant, text: errorMsg))
            if verboseLogging { print("[AHID Chat] \(errorCode): \(errorMsg)") }
        }
        isChatLoading = false
    }

    private func buildWeatherContext() -> String {
        guard let c = currentWeather, let d = dailyWeather else { return "" }
        let u = tempUnit
        return """
        Location: \(locationService.city)
        Now: \(Int(round(c.temperature_2m)))\(u) (feels \(Int(round(c.apparent_temperature)))\(u)), \(WeatherCode.description(for: c.weather_code))
        Humidity \(c.relative_humidity_2m)% | Cloud \(c.cloud_cover)% | Wind \(Int(round(c.wind_speed_10m)))mph \(WindHelper.degreeToCompass(c.wind_direction_10m)) gusts \(Int(round(c.wind_gusts_10m)))
        UV \(String(format: "%.1f", c.uv_index)) | Vis \(String(format: "%.1f", WeatherUnits.metersToMiles(c.visibility)))mi | Precip \(String(format: "%.1f", c.precipitation))mm/hr | AQI \(aqiValue) | Pressure \(pressureTrend.rawValue)
        Today H\(Int(round(d.temperature_2m_max[0])))\(u)/L\(Int(round(d.temperature_2m_min[0])))\(u) \(d.precipitation_probability_max[0])% precip
        """
    }

    // MARK: - AI Key Sync
    func syncAIKeys() async {
        await aiService.setKeys(
            anthropic: anthropicKey.isEmpty ? nil : anthropicKey,
            gemini:    geminiKey.isEmpty    ? nil : geminiKey,
            openai:    openaiKey.isEmpty    ? nil : openaiKey
        )
        await aiService.setConfig(timeout: aiTimeoutSeconds, maxTokens: aiMaxTokens)
    }

    // MARK: - Background Refresh
        private func startBackgroundRefresh() {
            guard autoRefreshEnabled else { return }
            let interval = TimeInterval(refreshIntervalMin * 60)
            Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                // Capture weak self directly inside the Task to satisfy Xcode 14
                Task { @MainActor [weak self] in
                    guard let self = self, self.autoRefreshEnabled else { return }
                    if self.verboseLogging { print("[AHID] Background refresh triggered") }
                    await self.fetchWeatherData()
                }
            }
        }

    func clearChatHistory() {
        chatMessages = []
    }
}
