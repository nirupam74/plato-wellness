//
//  ActivityAdvisory.swift
//  Wellness App
//
//  When someone flags an injury, stiff movement, or breathing trouble after a
//  session, we store an advisory with a suggested rest period and guidance. The
//  next time they open that same activity we surface it once: either "give it
//  more time" or "it has been long enough, ease back in". It never nags every
//  time. This is general wellness guidance, not medical advice.
//

import Foundation

struct ActivityAdvisory: Codable, Identifiable {
    var id: String
    var activityType: ActivityType
    var sportRaw: String?          // Sport.rawValue when the source was a sport
    var kind: IssueKind
    var area: String
    var note: String
    var recommendation: String
    var restDays: Int
    var reportedAt: Date
    var resolved: Bool
    var lastRemindedAt: Date?

    init(
        id: String = UUID().uuidString,
        activityType: ActivityType,
        sportRaw: String? = nil,
        kind: IssueKind,
        area: String,
        note: String,
        recommendation: String,
        restDays: Int,
        reportedAt: Date = Date(),
        resolved: Bool = false,
        lastRemindedAt: Date? = nil
    ) {
        self.id = id
        self.activityType = activityType
        self.sportRaw = sportRaw
        self.kind = kind
        self.area = area
        self.note = note
        self.recommendation = recommendation
        self.restDays = restDays
        self.reportedAt = reportedAt
        self.resolved = resolved
        self.lastRemindedAt = lastRemindedAt
    }

    /// The date the person could reasonably resume the activity.
    var canResumeDate: Date {
        Calendar.current.date(byAdding: .day, value: restDays, to: reportedAt) ?? reportedAt
    }

    /// Whole days left before the suggested resume date (0 once elapsed).
    func daysRemaining(asOf now: Date = Date()) -> Int {
        let days = Calendar.current.dateComponents([.day], from: now, to: canResumeDate).day ?? 0
        return max(0, days)
    }

    private var areaPhrase: String {
        area.trimmingCharacters(in: .whitespaces).isEmpty ? "" : " in your \(area.trimmingCharacters(in: .whitespaces).lowercased())"
    }

    /// The one-time message shown the next time the activity is opened.
    func reminderMessage(asOf now: Date = Date()) -> String {
        let remaining = daysRemaining(asOf: now)
        let what = kind.label.lowercased()
        if remaining > 0 {
            let dayWord = remaining == 1 ? "day" : "days"
            return "You flagged \(what)\(areaPhrase) recently. Consider giving it about \(remaining) more \(dayWord), or keep it easy today. \(recommendation)"
        } else {
            return "It has been long enough since you flagged \(what)\(areaPhrase). Ease back in and stop if it flares up. \(recommendation)"
        }
    }
}

/// Rule-based rest and guidance for a flagged issue. No server needed; the copy
/// is general guidance and always defers to a professional for anything serious.
enum InjuryAdvisor {
    static func advise(kind: IssueKind, area: String, activity: ActivityType) -> (restDays: Int, recommendation: String) {
        let a = area.lowercased()
        let joint = ["knee", "back", "ankle", "shoulder", "hamstring", "hip", "elbow", "wrist", "neck"]
        let isJoint = joint.contains { a.contains($0) }

        switch kind {
        case .injury:
            let days = isJoint ? 7 : 5
            return (days, "Rest and protect the area, use ice for swelling, and reintroduce gentle movement before load. If pain is sharp, worsening, or lasts beyond that, see a professional.")
        case .stiffness:
            return (2, "Warm up longer, mobilize the area, and keep the next couple of sessions at low intensity. Ease off if it does not loosen up.")
        case .breathing:
            return (2, "Keep intensity easy, breathe through the nose, and stop if it returns. If breathing trouble is severe or persistent, seek medical advice promptly.")
        case .other:
            return (1, "Take it easy next time and see how it feels. Stop early if anything does not feel right.")
        }
    }
}
