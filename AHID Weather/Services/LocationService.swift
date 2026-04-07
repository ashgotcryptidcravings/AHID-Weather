import Foundation
import CoreLocation

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var latitude: Double = 41.6389  // Toledo, OH fallback
    @Published var longitude: Double = -83.5780
    @Published var city: String = "TOLEDO"
    @Published var meta: String = "OHIO · US"
    @Published var usedFallback: Bool = true
    @Published var isLocating: Bool = false

    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<Bool, Never>?

    // Simulation support
    @Published var isSimulating: Bool = false
    var simulatedLat: Double = 40.7128
    var simulatedLon: Double = -74.0060

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

        // Read simulation settings from UserDefaults
        isSimulating = UserDefaults.standard.bool(forKey: "isSimulatingLocation")
        if let lat = Double(UserDefaults.standard.string(forKey: "simulatedLat") ?? "") {
            simulatedLat = lat
        }
        if let lon = Double(UserDefaults.standard.string(forKey: "simulatedLon") ?? "") {
            simulatedLon = lon
        }
    }

    func acquireLocation() async -> Bool {
        if isSimulating {
            latitude = simulatedLat
            longitude = simulatedLon
            usedFallback = false
            await reverseGeocode()
            return true
        }

        isLocating = true
        let status = locationManager.authorizationStatus

        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // Wait a moment for authorization
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }

        let currentStatus = locationManager.authorizationStatus
        #if os(macOS)
        let isAuthorized = currentStatus == .authorized || currentStatus == .authorizedAlways
        #else
        let isAuthorized = currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways
        #endif
        guard isAuthorized else {
            isLocating = false
            await reverseGeocode()
            return false
        }

        let got = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            self.continuation = cont
            self.locationManager.requestLocation()

            // Timeout after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if let c = self.continuation {
                    self.continuation = nil
                    c.resume(returning: false)
                }
            }
        }

        isLocating = false
        await reverseGeocode()
        return got
    }

    func reverseGeocode() async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let place = placemarks.first {
                city = (place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? "Unknown").uppercased()
                let state = place.administrativeArea ?? ""
                let country = place.isoCountryCode ?? ""
                meta = "\(state) · \(country)".uppercased()
            }
        } catch {
            // Also try Nominatim as backup
            await nominatimGeocode()
        }
    }

    private func nominatimGeocode() async {
        guard let url = URL(string: "https://nominatim.openstreetmap.org/reverse?lat=\(latitude)&lon=\(longitude)&format=json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let address = json["address"] as? [String: Any] {
                let cityName = (address["city"] as? String) ?? (address["town"] as? String) ?? (address["village"] as? String) ?? "Unknown"
                city = cityName.uppercased()
                let state = (address["state"] as? String) ?? ""
                let country = (address["country_code"] as? String)?.uppercased() ?? ""
                meta = "\(state) · \(country)".uppercased()
            }
        } catch {
            print("[AHID] Nominatim geocode failed: \(error.localizedDescription)")
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.usedFallback = false
            self.continuation?.resume(returning: true)
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[AHID] Location error: \(error.localizedDescription)")
        Task { @MainActor in
            self.continuation?.resume(returning: false)
            self.continuation = nil
        }
    }
}
