//
//  UserStore.swift
//  Wellness App
//
//  Owns the user profile, body measurements, and target recomputation.
//  Live: reads and writes users/{uid} and users/{uid}/measurements in Firestore.
//  Preview: in-memory sample data when constructed with seeded == true (uid nil).
//

import Foundation
import Observation
import FirebaseFirestore
import FirebaseStorage

@Observable
final class UserStore {
    var profile: UserProfile?
    var measurements: [BodyMeasurement]
    var progressPhotos: [ProgressPhoto]

    /// True once the first profile read has returned (doc present or not), so the
    /// UI can show a loading state instead of flashing onboarding.
    var isLoaded: Bool

    /// Onboarding is complete exactly when a profile document exists.
    var hasCompletedOnboarding: Bool { profile != nil }

    weak var healthKit: HealthKitManager?

    private let db = Firestore.firestore()
    private var uid: String?
    private var listeners: [ListenerRegistration] = []

    init(seeded: Bool = false) {
        if seeded {
            self.profile = SampleData.profile()
            self.measurements = SampleData.measurements().sorted { $0.recordedAt > $1.recordedAt }
            self.isLoaded = true
        } else {
            self.profile = nil
            self.measurements = []
            self.isLoaded = false
        }
        self.progressPhotos = []
    }

    // MARK: - Firestore binding

    func bind(uid: String?) {
        self.uid = uid
        listeners.forEach { $0.remove() }
        listeners = []

        guard let uid else {
            profile = nil
            measurements = []
            progressPhotos = []
            isLoaded = false
            return
        }

        listeners.append(
            db.document("users/\(uid)").addSnapshotListener { [weak self] snap, _ in
                self?.profile = try? snap?.data(as: UserProfile.self)
                self?.isLoaded = true
            }
        )
        listeners.append(
            db.collection("users/\(uid)/measurements").addSnapshotListener { [weak self] snap, _ in
                guard let snap else { return }
                self?.measurements = snap.documents
                    .compactMap { try? $0.data(as: BodyMeasurement.self) }
                    .sorted { $0.recordedAt > $1.recordedAt }
            }
        )
        listeners.append(
            db.collection("users/\(uid)/progressPhotos")
                .order(by: "recordedAt", descending: true)
                .limit(to: 300)
                .addSnapshotListener { [weak self] snap, _ in
                    guard let snap else { return }
                    self?.progressPhotos = snap.documents
                        .compactMap { try? $0.data(as: ProgressPhoto.self) }
                        .sorted { $0.recordedAt > $1.recordedAt }
                }
        )
    }

    // MARK: - Onboarding

    func completeOnboarding(with profile: UserProfile) {
        if let uid {
            try? db.document("users/\(uid)").setData(from: profile)
        } else {
            self.profile = profile
        }
    }

    // MARK: - Editing

    func update(_ transform: (inout UserProfile) -> Void) {
        guard var p = profile else { return }
        transform(&p)
        if let uid {
            try? db.document("users/\(uid)").setData(from: p, merge: true)
        } else {
            profile = p
        }
    }

    func recomputedTargets() -> DailyTargets? {
        guard let p = profile else { return nil }
        return HealthMath.dailyTargets(
            weightKg: p.currentWeightKg,
            heightCm: p.heightCm,
            ageYears: p.age(),
            sex: p.biologicalSex,
            activityLevel: p.activityLevel,
            goal: p.goal,
            weeklyRateKg: p.weeklyRateKg
        )
    }

    func applyTargets(_ targets: DailyTargets) {
        update { $0.targets = targets }
    }

    var requestedTargetIsUnsafe: Bool {
        guard let p = profile else { return false }
        let tdee = HealthMath.tdee(
            bmr: HealthMath.bmr(weightKg: p.currentWeightKg, heightCm: p.heightCm, ageYears: p.age(), sex: p.biologicalSex),
            activityLevel: p.activityLevel
        )
        let raw = HealthMath.calorieTarget(tdee: tdee, goal: p.goal, weeklyRateKg: p.weeklyRateKg)
        return HealthMath.isBelowSafeFloor(raw, sex: p.biologicalSex)
    }

    // MARK: - Body measurements

    func addMeasurement(_ measurement: BodyMeasurement) {
        if let uid {
            try? db.collection("users/\(uid)/measurements").document(measurement.id).setData(from: measurement)
            if let w = measurement.weightKg {
                update { $0.currentWeightKg = w }
                healthKit?.saveWeight(kg: w, date: measurement.recordedAt)
            }
        } else {
            measurements.insert(measurement, at: 0)
            measurements.sort { $0.recordedAt > $1.recordedAt }
            if let w = measurement.weightKg {
                update { $0.currentWeightKg = w }
            }
        }
    }

    func logWeight(_ kg: Double, at date: Date = Date()) {
        addMeasurement(BodyMeasurement(weightKg: kg, recordedAt: date))
    }

    // MARK: - Progress photos

    /// Upload image bytes to Storage and record the download URL in Firestore.
    func uploadPhoto(_ data: Data) async {
        guard let uid else { return }
        let id = UUID().uuidString
        let ref = Storage.storage().reference().child("users/\(uid)/progressPhotos/\(id).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        do {
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            let photo = ProgressPhoto(id: id, url: url.absoluteString)
            try db.collection("users/\(uid)/progressPhotos").document(id).setData(from: photo)
        } catch {
            // Non fatal: the user can retry. Manual entry is unaffected.
        }
    }

    var weightSeries: [(date: Date, weightKg: Double)] {
        measurements
            .compactMap { m in m.weightKg.map { (m.recordedAt, $0) } }
            .sorted { $0.0 < $1.0 }
    }

    var currentWeightKg: Double? { profile?.currentWeightKg }
}
