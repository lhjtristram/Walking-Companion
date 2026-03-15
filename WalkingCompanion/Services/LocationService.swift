import Foundation
import CoreLocation
import Observation

/// Streams GPS data (distance, pace) during a walk.
@MainActor
@Observable
final class LocationService: NSObject {
    private(set) var distance: Double = 0     // metres accumulated
    private(set) var pace: Double = 0         // seconds per kilometre (0 = no data yet)
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var isTracking = false
    private var speedSamples: [Double] = []   // m/s samples for rolling pace

    // MARK: — Lifecycle

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5            // update every 5 m
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissions() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        distance = 0
        pace = 0
        lastLocation = nil
        speedSamples = []
        isTracking = true
        manager.startUpdatingLocation()
    }

    func stop() {
        isTracking = false
        manager.stopUpdatingLocation()
    }

    // MARK: — Private

    private func updatePace(from location: CLLocation) {
        guard location.speed >= 0 else { return }   // negative speed = invalid
        speedSamples.append(location.speed)
        if speedSamples.count > 10 { speedSamples.removeFirst() }

        let avgSpeed = speedSamples.reduce(0, +) / Double(speedSamples.count)
        guard avgSpeed > 0.3 else { return }         // ignore standing still (< ~1 km/h)
        pace = 1000 / avgSpeed                       // seconds per km
    }
}

// MARK: — CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }

        Task { @MainActor in
            guard self.isTracking else { return }

            if let prev = self.lastLocation, latest.horizontalAccuracy < 20 {
                let delta = latest.distance(from: prev)
                if delta > 0 { self.distance += delta }
            }

            self.lastLocation = latest
            self.updatePace(from: latest)
        }
    }
}
