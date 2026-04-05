import Foundation

actor WeatherService {
    private var cachedWeather: (weather: OpenMeteoResponse, aqi: AirQualityResponse, time: Date)?
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    func fetchWeather(lat: Double, lon: Double, useCelsius: Bool, force: Bool = false) async throws -> (OpenMeteoResponse, AirQualityResponse) {
        if !force, let cached = cachedWeather, Date().timeIntervalSince(cached.time) < cacheTTL {
            return (cached.weather, cached.aqi)
        }

        let tempUnit = useCelsius ? "celsius" : "fahrenheit"

        let weatherURL = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code"
            + ",surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m"
            + ",precipitation,cloud_cover,visibility,uv_index,dew_point_2m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + ",precipitation_probability_max,sunrise,sunset,uv_index_max,et0_fao_evapotranspiration"
            + "&hourly=temperature_2m,apparent_temperature,weather_code,precipitation_probability"
            + ",wind_speed_10m,wind_direction_10m,relative_humidity_2m"
            + ",snow_depth,soil_temperature_0cm,surface_pressure"
            + "&temperature_unit=\(tempUnit)&wind_speed_unit=mph"
            + "&precipitation_unit=mm&timezone=auto&forecast_days=7"

        let aqiURL = "https://air-quality-api.open-meteo.com/v1/air-quality"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&current=pm10,pm2_5,nitrogen_dioxide,ozone&timezone=auto"

        do {
            async let weatherData = fetchJSON(from: weatherURL, as: OpenMeteoResponse.self, provider: "Open-Meteo")
            async let aqiData    = fetchJSON(from: aqiURL,     as: AirQualityResponse.self, provider: "Open-Meteo AQI")
            let (weather, aqi) = try await (weatherData, aqiData)
            cachedWeather = (weather, aqi, Date())
            return (weather, aqi)
        } catch let err as AppError {
            throw err
        } catch {
            throw AppError.wx005_noData
        }
    }

    func clearCache() {
        cachedWeather = nil
    }

    // MARK: - Private

    private func fetchJSON<T: Decodable>(from urlString: String, as type: T.Type, provider: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw AppError.wx001_invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw AppError.wx002_networkTimeout
        } catch {
            throw AppError.wx002_networkTimeout
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.wx005_noData
        }

        guard http.statusCode == 200 else {
            throw AppError.wx003_httpError(http.statusCode, provider)
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw AppError.wx004_decodeFailed(error.localizedDescription)
        }
    }
}
