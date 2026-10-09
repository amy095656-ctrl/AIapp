import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // 預設參考中心點：台北車站（方便測試或未開啟定位時提供預覽）
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5170)

    @Published var userLocation: CLLocationCoordinate2D? = LocationManager.defaultCoordinate
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocating: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // 每移動 10 公尺更新
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        isLocating = true
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
        isLocating = false
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // 維持預設位置
            if userLocation == nil {
                userLocation = LocationManager.defaultCoordinate
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.isLocating = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isLocating = false
        }
    }
}
