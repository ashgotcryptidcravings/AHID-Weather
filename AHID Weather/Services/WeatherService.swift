import Foundation

actor WeatherService {
    private var cachedWeather: (weather: OpenMeteoResponse, aqi: AirQualityResponse, time: Date)?
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    func fetchWeather(lat: Double, lon: Double, useCelsius: Bool, force: Bool = false) async throws -> (OpenMeteoResponse, AirQualityResponse) {
        // Check cache
        if !force, let cached = cachedWeather, Date().timeIntervalSince(cached.time) < cacheTTL {
            return (cached.weather, cached.aqi)
        }

        let tempUnit = useCelsius ? "celsius" : "fahrenheit"
        let weatherURL = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)"
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,cloud_cover,visibility,uv_index,dew_point_2m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_max,et0_fao_evapotranspiration"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,wind_speed_10m,snow_depth,soil_temperature_0cm"
            + "&temperature_unit=\(tempUnit)&wind_speed_unit=mph&precipitation_unit=mm&timezone=auto&forecast_days=7"

        let aqiURL = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(lat)&longitude=\(lon)&current=pm10,pm2_5,nitrogen_dioxide,ozone&timezone=auto"

        async let weatherData = fetchJSON(from: weatherURL, as: OpenMeteoResponse.self)
        async let aqiData = fetchJSON(from: aqiURL, as: AirQualityResponse.self)

        let (weather, aqi) = try await (weatherData, aqiData)
        cachedWeather = (weather, aqi, Date())
        return (weather, aqi)
    }

    func clearCache() {
        cachedWeather = nil
    }

    private func fetchJSON<T: Decodable>(from urlString: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WeatherError.httpError(statusCode)
        }

        return try JSONDecoder().decode(type, from: data)
    }
}

enum WeatherError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(let code): return "HTTP Error \(code)"
        case .noData: return "No data received"
        }
    }
}
