//
//  ActivityDetailModels.swift
//  Wellness App
//
//  Rich detail for activity logging: a broad sport catalogue with context
//  (position, venue, participants), swim specifics, and full strength training
//  (exercises with sets, reps, weight, and rest). These feed a more accurate
//  calorie estimate and can be saved as templates to reuse. All types are
//  optional on ActivityEntry so older entries still decode.
//

import Foundation

// MARK: - Sports

/// A broad catalogue of popular sports, each with a representative MET value
/// (Compendium of Physical Activities, general effort) used for estimates.
enum Sport: String, Codable, CaseIterable, Identifiable {
    case soccer, basketball, americanFootball, tennis, baseball, softball
    case volleyball, iceHockey, fieldHockey, cricket, rugby, badminton
    case tableTennis, golf, ultimateFrisbee, lacrosse, handball, squash
    case racquetball, pickleball, boxing, martialArts, wrestling, rockClimbing
    case skiing, snowboarding, skateboarding, surfing, rowing, dance, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .soccer:          "Soccer"
        case .basketball:      "Basketball"
        case .americanFootball:"American football"
        case .tennis:          "Tennis"
        case .baseball:        "Baseball"
        case .softball:        "Softball"
        case .volleyball:      "Volleyball"
        case .iceHockey:       "Ice hockey"
        case .fieldHockey:     "Field hockey"
        case .cricket:         "Cricket"
        case .rugby:           "Rugby"
        case .badminton:       "Badminton"
        case .tableTennis:     "Table tennis"
        case .golf:            "Golf"
        case .ultimateFrisbee: "Ultimate frisbee"
        case .lacrosse:        "Lacrosse"
        case .handball:        "Handball"
        case .squash:          "Squash"
        case .racquetball:     "Racquetball"
        case .pickleball:      "Pickleball"
        case .boxing:          "Boxing"
        case .martialArts:     "Martial arts"
        case .wrestling:       "Wrestling"
        case .rockClimbing:    "Rock climbing"
        case .skiing:          "Skiing"
        case .snowboarding:    "Snowboarding"
        case .skateboarding:   "Skateboarding"
        case .surfing:         "Surfing"
        case .rowing:          "Rowing"
        case .dance:           "Dance"
        case .other:           "Other sport"
        }
    }

    var systemImage: String {
        switch self {
        case .soccer:          "soccerball"
        case .basketball:      "basketball.fill"
        case .americanFootball:"football.fill"
        case .tennis:          "tennis.racket"
        case .baseball, .softball: "baseball.fill"
        case .volleyball:      "volleyball.fill"
        case .iceHockey:       "hockey.puck.fill"
        case .fieldHockey:     "figure.field.hockey"
        case .cricket:         "cricket.ball.fill"
        case .rugby:           "rugbyball.fill"
        case .badminton:       "figure.badminton"
        case .tableTennis:     "figure.table.tennis"
        case .golf:            "figure.golf"
        case .ultimateFrisbee: "figure.disc.sports"
        case .lacrosse:        "figure.lacrosse"
        case .handball:        "figure.handball"
        case .squash:          "figure.squash"
        case .racquetball:     "figure.racquetball"
        case .pickleball:      "figure.pickleball"
        case .boxing:          "figure.boxing"
        case .martialArts:     "figure.martial.arts"
        case .wrestling:       "figure.wrestling"
        case .rockClimbing:    "figure.climbing"
        case .skiing:          "figure.skiing.downhill"
        case .snowboarding:    "figure.snowboarding"
        case .skateboarding:   "skateboard"
        case .surfing:         "figure.surfing"
        case .rowing:          "figure.rowing"
        case .dance:           "figure.dance"
        case .other:           "sportscourt"
        }
    }

    /// Whether a playing position makes sense to capture for this sport.
    var usesPosition: Bool {
        switch self {
        case .soccer, .basketball, .americanFootball, .baseball, .softball,
             .volleyball, .iceHockey, .fieldHockey, .cricket, .rugby,
             .lacrosse, .handball:
            return true
        default:
            return false
        }
    }

    /// Representative MET for a general-effort session; scaled by intensity.
    var met: Double {
        switch self {
        case .soccer:          7.0
        case .basketball:      8.0
        case .americanFootball:8.0
        case .tennis:          7.3
        case .baseball, .softball: 5.0
        case .volleyball:      6.0
        case .iceHockey:       8.0
        case .fieldHockey:     7.8
        case .cricket:         5.0
        case .rugby:           8.3
        case .badminton:       5.5
        case .tableTennis:     4.0
        case .golf:            4.8
        case .ultimateFrisbee: 8.0
        case .lacrosse:        8.0
        case .handball:        8.0
        case .squash:          7.3
        case .racquetball:     7.0
        case .pickleball:      6.0
        case .boxing:          9.0
        case .martialArts:     10.3
        case .wrestling:       6.0
        case .rockClimbing:    8.0
        case .skiing:          7.0
        case .snowboarding:    5.3
        case .skateboarding:   5.0
        case .surfing:         3.0
        case .rowing:          7.0
        case .dance:           7.8
        case .other:           7.0
        }
    }

    /// Sports offered in the picker. `other` stays in the enum for decoding old
    /// entries but is no longer selectable.
    static var selectable: [Sport] { allCases.filter { $0 != .other } }

    /// Sport-specific stat fields the user can record for this sport. Empty for
    /// sports where per-game box-score stats do not apply.
    var statFields: [String] {
        switch self {
        case .basketball:      return ["Points", "Rebounds", "Assists", "Steals", "Blocks"]
        case .soccer:          return ["Goals", "Assists", "Shots", "Saves"]
        case .americanFootball:return ["Touchdowns", "Yards", "Tackles"]
        case .baseball, .softball: return ["Hits", "Runs", "RBIs", "Strikeouts"]
        case .volleyball:      return ["Kills", "Blocks", "Aces", "Digs"]
        case .iceHockey, .fieldHockey: return ["Goals", "Assists", "Shots", "Saves"]
        case .cricket:         return ["Runs", "Wickets", "Catches"]
        case .rugby:           return ["Tries", "Tackles"]
        case .lacrosse:        return ["Goals", "Assists", "Ground balls"]
        case .handball:        return ["Goals", "Assists", "Saves"]
        case .tennis, .badminton, .tableTennis, .squash, .racquetball, .pickleball:
            return ["Sets won", "Games won", "Aces"]
        case .golf:            return ["Score", "Putts"]
        default:               return []
        }
    }
}

/// Where a sport was played.
enum SportVenue: String, Codable, CaseIterable, Identifiable {
    case court, field, gym, park, driveway, home, rink, studio, beach, track, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .court:    "Court"
        case .field:    "Field"
        case .gym:      "Gym"
        case .park:     "Park"
        case .driveway: "Driveway"
        case .home:     "Home"
        case .rink:     "Rink"
        case .studio:   "Studio"
        case .beach:    "Beach"
        case .track:    "Track"
        case .other:    "Other"
        }
    }

    /// Venues offered in the picker (`other` kept only for decoding).
    static var selectable: [SportVenue] { allCases.filter { $0 != .other } }
}

/// Context captured for a sport session, all optional and refine the estimate.
struct SportDetails: Codable {
    var sport: Sport
    var intensity: ActivityIntensity
    var venue: SportVenue
    var isOutdoor: Bool
    var participants: Int   // people you played with (0 = solo / practice)
    var position: String    // free text; only meaningful when sport.usesPosition
    // Per-sport box-score stats keyed by field label (e.g. "Points": 20).
    var stats: [String: Int]?
}

// MARK: - Swim

enum PoolType: String, Codable, CaseIterable, Identifiable {
    case indoorPool, outdoorPool, openWater
    var id: String { rawValue }
    var label: String {
        switch self {
        case .indoorPool:  "Indoor pool"
        case .outdoorPool: "Outdoor pool"
        case .openWater:   "Open water"
        }
    }
}

struct SwimDetails: Codable {
    var poolType: PoolType
    var poolLengthM: Int?  // e.g. 25 or 50
    var laps: Int?
    var intensity: ActivityIntensity
}

// MARK: - Strength training

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, arms, core, fullBody
    var id: String { rawValue }
    var label: String {
        switch self {
        case .chest:     "Chest"
        case .back:      "Back"
        case .legs:      "Legs"
        case .shoulders: "Shoulders"
        case .arms:      "Arms"
        case .core:      "Core"
        case .fullBody:  "Full body"
        }
    }
}

/// A broad list of common gym exercises grouped by primary muscle.
enum GymExercise: String, Codable, CaseIterable, Identifiable {
    // Chest
    case benchPress, inclineBenchPress, dumbbellPress, chestFly, pushUp, cableCrossover, dip
    // Back
    case deadlift, pullUp, latPulldown, barbellRow, dumbbellRow, seatedCableRow, facePull
    // Legs
    case backSquat, frontSquat, legPress, lunge, romanianDeadlift, legExtension, legCurl, calfRaise, hipThrust
    // Shoulders
    case overheadPress, dumbbellShoulderPress, lateralRaise, frontRaise, reverseFly, shrug
    // Arms
    case bicepCurl, hammerCurl, preacherCurl, tricepPushdown, skullCrusher, closeGripBenchPress
    // Core
    case plank, crunch, hangingLegRaise, russianTwist, cableWoodchop, backExtension
    // Full body
    case cleanAndPress, kettlebellSwing, thruster, burpee

    var id: String { rawValue }

    var group: MuscleGroup {
        switch self {
        case .benchPress, .inclineBenchPress, .dumbbellPress, .chestFly, .pushUp, .cableCrossover, .dip:
            return .chest
        case .deadlift, .pullUp, .latPulldown, .barbellRow, .dumbbellRow, .seatedCableRow, .facePull:
            return .back
        case .backSquat, .frontSquat, .legPress, .lunge, .romanianDeadlift, .legExtension, .legCurl, .calfRaise, .hipThrust:
            return .legs
        case .overheadPress, .dumbbellShoulderPress, .lateralRaise, .frontRaise, .reverseFly, .shrug:
            return .shoulders
        case .bicepCurl, .hammerCurl, .preacherCurl, .tricepPushdown, .skullCrusher, .closeGripBenchPress:
            return .arms
        case .plank, .crunch, .hangingLegRaise, .russianTwist, .cableWoodchop, .backExtension:
            return .core
        case .cleanAndPress, .kettlebellSwing, .thruster, .burpee:
            return .fullBody
        }
    }

    var label: String {
        switch self {
        case .benchPress:           "Bench press"
        case .inclineBenchPress:    "Incline bench press"
        case .dumbbellPress:        "Dumbbell press"
        case .chestFly:             "Chest fly"
        case .pushUp:               "Push-up"
        case .cableCrossover:       "Cable crossover"
        case .dip:                  "Dip"
        case .deadlift:             "Deadlift"
        case .pullUp:               "Pull-up"
        case .latPulldown:          "Lat pulldown"
        case .barbellRow:           "Barbell row"
        case .dumbbellRow:          "Dumbbell row"
        case .seatedCableRow:       "Seated cable row"
        case .facePull:             "Face pull"
        case .backSquat:            "Back squat"
        case .frontSquat:           "Front squat"
        case .legPress:             "Leg press"
        case .lunge:                "Lunge"
        case .romanianDeadlift:     "Romanian deadlift"
        case .legExtension:         "Leg extension"
        case .legCurl:              "Leg curl"
        case .calfRaise:            "Calf raise"
        case .hipThrust:            "Hip thrust"
        case .overheadPress:        "Overhead press"
        case .dumbbellShoulderPress:"Dumbbell shoulder press"
        case .lateralRaise:         "Lateral raise"
        case .frontRaise:           "Front raise"
        case .reverseFly:           "Reverse fly"
        case .shrug:                "Shrug"
        case .bicepCurl:            "Bicep curl"
        case .hammerCurl:           "Hammer curl"
        case .preacherCurl:         "Preacher curl"
        case .tricepPushdown:       "Tricep pushdown"
        case .skullCrusher:         "Skull crusher"
        case .closeGripBenchPress:  "Close-grip bench press"
        case .plank:                "Plank"
        case .crunch:               "Crunch"
        case .hangingLegRaise:      "Hanging leg raise"
        case .russianTwist:         "Russian twist"
        case .cableWoodchop:        "Cable woodchop"
        case .backExtension:        "Back extension"
        case .cleanAndPress:        "Clean and press"
        case .kettlebellSwing:      "Kettlebell swing"
        case .thruster:             "Thruster"
        case .burpee:               "Burpee"
        }
    }

    static func inGroup(_ group: MuscleGroup) -> [GymExercise] {
        allCases.filter { $0.group == group }
    }
}

/// One set within a strength exercise.
struct StrengthSet: Codable, Identifiable {
    var id: String
    var reps: Int
    var weightKg: Double
    var restSec: Int

    init(id: String = UUID().uuidString, reps: Int = 10, weightKg: Double = 0, restSec: Int = 90) {
        self.id = id
        self.reps = reps
        self.weightKg = weightKg
        self.restSec = restSec
    }
}

/// One exercise and its sets within a strength session.
struct StrengthEntry: Codable, Identifiable {
    var id: String
    var exercise: GymExercise
    var sets: [StrengthSet]

    init(id: String = UUID().uuidString, exercise: GymExercise, sets: [StrengthSet] = [StrengthSet()]) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
    }

    var totalReps: Int { sets.reduce(0) { $0 + $1.reps } }
    /// Total volume (weight times reps) in kg, a common strength-load measure.
    var volumeKg: Double { sets.reduce(0) { $0 + $1.weightKg * Double($1.reps) } }
}

// MARK: - Session feedback

enum SessionDifficulty: String, Codable, CaseIterable, Identifiable {
    case veryEasy, easy, moderate, hard, maxEffort
    var id: String { rawValue }
    var label: String {
        switch self {
        case .veryEasy:  "Very easy"
        case .easy:      "Easy"
        case .moderate:  "Moderate"
        case .hard:      "Hard"
        case .maxEffort: "All out"
        }
    }
}

/// The kind of issue a person can flag after a session. Injury, stiffness, and
/// breathing all trigger a rest recommendation and a next-time reminder.
enum IssueKind: String, Codable, CaseIterable, Identifiable {
    case injury, stiffness, breathing, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .injury:    "Injury or pain"
        case .stiffness: "Stiff or uneasy movement"
        case .breathing: "Breathing difficulty"
        case .other:     "Something else"
        }
    }
    var systemImage: String {
        switch self {
        case .injury:    "bandage.fill"
        case .stiffness: "figure.walk.motion"
        case .breathing: "lungs.fill"
        case .other:     "exclamationmark.bubble.fill"
        }
    }
}

/// One thing that did not feel right during a session.
struct SessionIssue: Codable, Identifiable {
    var id: String
    var kind: IssueKind
    var area: String   // e.g. "Left knee", "Lower back"
    var note: String

    init(id: String = UUID().uuidString, kind: IssueKind = .injury, area: String = "", note: String = "") {
        self.id = id
        self.kind = kind
        self.area = area
        self.note = note
    }

    var isEmpty: Bool {
        area.trimmingCharacters(in: .whitespaces).isEmpty && note.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// How a session felt, plus anything that went well or did not feel right.
struct SessionFeedback: Codable {
    var difficulty: SessionDifficulty
    var wentWell: String
    var issues: [SessionIssue]

    var isEmpty: Bool {
        wentWell.trimmingCharacters(in: .whitespaces).isEmpty && issues.isEmpty
    }
}

// MARK: - Combined detail

/// Optional rich detail attached to an ActivityEntry. Only the branch matching
/// the activity type is populated.
struct ActivityDetails: Codable {
    var sport: SportDetails?
    var swim: SwimDetails?
    var strength: [StrengthEntry]?
    var feedback: SessionFeedback?
    var notes: String?

    var isEmpty: Bool {
        sport == nil && swim == nil && (strength?.isEmpty ?? true)
            && (feedback?.isEmpty ?? true) && (notes?.isEmpty ?? true)
    }
}

// MARK: - Reusable template

/// A saved activity the user can pick again next time they do it.
struct ActivityTemplate: Codable, Identifiable {
    var id: String
    var name: String
    var type: ActivityType
    var durationMin: Int
    var details: ActivityDetails?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        type: ActivityType,
        durationMin: Int,
        details: ActivityDetails? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.durationMin = durationMin
        self.details = details
        self.createdAt = createdAt
    }
}
