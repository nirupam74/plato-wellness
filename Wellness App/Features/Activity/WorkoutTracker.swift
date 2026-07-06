//
//  WorkoutTracker.swift
//  Wellness App
//
//  Live GPS workout tracking: distance, duration, pace, and the route, using
//  Core Location while the workout screen is open. Heart rate is not available
//  from the phone alone (that needs an Apple Watch or a paired monitor); users
//  can add an average heart rate afterwards when editing the session.
//

import Foundation
import CoreLocation
import Observation

@Observable
final class WorkoutTracker: NSObject, CLLocationManagerDelegate {
    enum Phase { case idle, tracking, paused, finished }

    private let manager = CLLocationManager()
    private var displayTimer: Timer?
    private var lastPoint: CLLocation?
    private var segmentStart: Date?
    private var accumulated: TimeInterval = 0

    private(set) var phase: Phase = .idle
    private(set) var authorization: CLAuthorizationStatus
    private(set) var distanceMeters: Double = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var currentSpeed: Double = 0            // metres/second
    private(set) var coordinates: [CLLocationCoordinate2D] = []
    private(set) var startLocation: CLLocation?

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 5
        manager.activityType = .fitness
    }

    var locationAllowed: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    func requestAuthorization() { manager.requestWhenInUseAuthorization() }

    func start() {
        distanceMeters = 0
        elapsed = 0
        accumulated = 0
        coordinates = []
        lastPoint = nil
        startLocation = nil
        segmentStart = Date()
        phase = .tracking
        manager.startUpdatingLocation()
        startTimer()
    }

    func pause() {
        guard phase == .tracking else { return }
        accumulated = elapsed
        phase = .paused
        manager.stopUpdatingLocation()
        stopTimer()
    }

    func resume() {
        guard phase == .paused else { return }
        segmentStart = Date()
        phase = .tracking
        manager.startUpdatingLocation()
        startTimer()
    }

    func stop() {
        phase = .finished
        manager.stopUpdatingLocation()
        stopTimer()
    }

    func reset() {
        stopTimer()
        manager.stopUpdatingLocation()
        phase = .idle
        distanceMeters = 0
        elapsed = 0
        accumulated = 0
        coordinates = []
        lastPoint = nil
        startLocation = nil
    }

    // MARK: - Derived values

    var distanceKm: Double { distanceMeters / 1000 }
    var durationMinutes: Int { max(0, Int((elapsed / 60).rounded())) }
    var averageSpeedKmh: Double { elapsed > 0 ? distanceKm / (elapsed / 3600) : 0 }

    /// Pace in minutes per kilometre (nil until there is distance).
    var paceMinPerKm: Double? {
        guard distanceKm > 0.01 else { return nil }
        return (elapsed / 60) / distanceKm
    }

    var paceText: String {
        guard let pace = paceMinPerKm, pace.isFinite else { return "--" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    /// A rough intensity label from current speed relative to the activity.
    func intensity(for type: ActivityType) -> ActivityIntensity {
        let kmh = averageSpeedKmh
        switch type {
        case .run:
            if kmh > 11 { return .high }
            if kmh > 7 { return .medium }
            return .low
        case .ride:
            if kmh > 25 { return .high }
            if kmh > 16 { return .medium }
            return .low
        case .walk:
            if kmh > 6 { return .high }
            if kmh > 4 { return .medium }
            return .low
        default:
            return .medium
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.segmentStart else { return }
            self.elapsed = self.accumulated + Date().timeIntervalSince(start)
        }
    }

    private func stopTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard phase == .tracking else { return }
        for location in locations {
            guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else { continue }
            if startLocation == nil { startLocation = location }
            if let last = lastPoint {
                let step = location.distance(from: last)
                if step > 1 { distanceMeters += step }
            }
            lastPoint = location
            currentSpeed = max(0, location.speed)
            coordinates.append(location.coordinate)
        }
    }
}
