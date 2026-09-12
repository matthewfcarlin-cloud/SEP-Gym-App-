import Foundation

/// A single piece of equipment on the gym floor.
struct Machine: Identifiable, Hashable {
    let id: String
    let name: String
    let group: String
    /// How many of this machine the gym owns.
    let stations: Int
    /// How long one person occupies it, sets and rest included.
    let minutes: Int
    let symbol: String

    static let catalog: [Machine] = [
        Machine(id: "squat-rack", name: "Squat Rack", group: "legs", stations: 3, minutes: 12, symbol: "figure.strengthtraining.traditional"),
        Machine(id: "leg-press", name: "Leg Press", group: "legs", stations: 2, minutes: 10, symbol: "figure.strengthtraining.functional"),
        Machine(id: "hack-squat", name: "Hack Squat", group: "legs", stations: 1, minutes: 10, symbol: "bolt.fill"),
        Machine(id: "leg-ext", name: "Leg Extension", group: "legs", stations: 2, minutes: 7, symbol: "figure.flexibility"),
        Machine(id: "leg-curl", name: "Seated Leg Curl", group: "legs", stations: 2, minutes: 7, symbol: "arrow.triangle.2.circlepath"),
        Machine(id: "hip-thrust", name: "Hip Thrust", group: "legs", stations: 1, minutes: 9, symbol: "figure.core.training"),
        Machine(id: "calf-raise", name: "Calf Raise", group: "legs", stations: 2, minutes: 6, symbol: "shoeprints.fill"),

        Machine(id: "bench", name: "Bench Press", group: "push", stations: 3, minutes: 12, symbol: "dumbbell.fill"),
        Machine(id: "incline-db", name: "Incline Dumbbell", group: "push", stations: 4, minutes: 10, symbol: "dumbbell"),
        Machine(id: "chest-press", name: "Chest Press", group: "push", stations: 2, minutes: 8, symbol: "rectangle.compress.vertical"),
        Machine(id: "shoulder-press", name: "Shoulder Press", group: "push", stations: 2, minutes: 8, symbol: "figure.arms.open"),
        Machine(id: "cable-fly", name: "Cable Fly", group: "push", stations: 2, minutes: 7, symbol: "arrow.left.and.right"),
        Machine(id: "tricep-push", name: "Tricep Pushdown", group: "push", stations: 2, minutes: 6, symbol: "arrow.down.to.line"),

        Machine(id: "pullup", name: "Pull-Up Bar", group: "pull", stations: 2, minutes: 8, symbol: "figure.climbing"),
        Machine(id: "lat-pulldown", name: "Lat Pulldown", group: "pull", stations: 2, minutes: 9, symbol: "arrow.down.to.line.compact"),
        Machine(id: "seated-row", name: "Seated Cable Row", group: "pull", stations: 2, minutes: 9, symbol: "figure.rowing"),
        Machine(id: "chest-row", name: "Chest-Supported Row", group: "pull", stations: 1, minutes: 9, symbol: "arrow.backward.to.line"),
        Machine(id: "face-pull", name: "Face Pull", group: "pull", stations: 2, minutes: 6, symbol: "arrow.up.backward"),
        Machine(id: "cable-curl", name: "Cable Curl", group: "pull", stations: 2, minutes: 7, symbol: "arrow.turn.up.left"),
        Machine(id: "preacher", name: "Preacher Curl", group: "pull", stations: 1, minutes: 7, symbol: "figure.wave"),

        Machine(id: "cable-crunch", name: "Cable Crunch", group: "core", stations: 2, minutes: 6, symbol: "circle.grid.cross.fill"),
        Machine(id: "ab-machine", name: "Ab Machine", group: "core", stations: 1, minutes: 6, symbol: "circle.hexagongrid.fill"),
    ]

    static let byID: [String: Machine] = Dictionary(
        uniqueKeysWithValues: catalog.map { ($0.id, $0) }
    )
}

/// A named day type. `exercises` is ordered by training priority: index 0 is the
/// heaviest compound and should stay early in the session if at all possible.
struct Split: Identifiable, Hashable {
    let id: String
    let name: String
    let tag: String
    let colorHex: String
    let exercises: [String]

    var isRest: Bool { exercises.isEmpty }

    static let catalog: [Split] = [
        Split(id: "push", name: "Push", tag: "Chest · Shoulders · Triceps", colorHex: "FF6B4A",
              exercises: ["bench", "incline-db", "shoulder-press", "chest-press", "cable-fly", "tricep-push"]),
        Split(id: "pull", name: "Pull", tag: "Back · Biceps", colorHex: "4AC8FF",
              exercises: ["pullup", "lat-pulldown", "seated-row", "chest-row", "face-pull", "cable-curl"]),
        Split(id: "legs", name: "Legs", tag: "Quads · Hams · Glutes", colorHex: "C6F24E",
              exercises: ["squat-rack", "leg-press", "hack-squat", "leg-curl", "leg-ext", "calf-raise"]),
        Split(id: "upper", name: "Upper Body", tag: "Full upper", colorHex: "B07BFF",
              exercises: ["bench", "lat-pulldown", "shoulder-press", "seated-row", "cable-curl", "tricep-push"]),
        Split(id: "lower", name: "Lower Body", tag: "Legs · Glutes · Core", colorHex: "FFD24A",
              exercises: ["squat-rack", "hip-thrust", "leg-press", "leg-curl", "calf-raise", "cable-crunch"]),
        Split(id: "full", name: "Full Body", tag: "Everything", colorHex: "4AFFC0",
              exercises: ["squat-rack", "bench", "lat-pulldown", "leg-press", "shoulder-press", "ab-machine"]),
        Split(id: "rest", name: "Rest", tag: "Recovery day", colorHex: "5A6472", exercises: []),
    ]

    static let byID: [String: Split] = Dictionary(
        uniqueKeysWithValues: catalog.map { ($0.id, $0) }
    )

    static let rest = byID["rest"]!
}

struct Weekday: Identifiable, Hashable {
    let id: String
    let short: String
    let name: String

    static let week: [Weekday] = [
        Weekday(id: "mon", short: "MON", name: "Monday"),
        Weekday(id: "tue", short: "TUE", name: "Tuesday"),
        Weekday(id: "wed", short: "WED", name: "Wednesday"),
        Weekday(id: "thu", short: "THU", name: "Thursday"),
        Weekday(id: "fri", short: "FRI", name: "Friday"),
        Weekday(id: "sat", short: "SAT", name: "Saturday"),
        Weekday(id: "sun", short: "SUN", name: "Sunday"),
    ]

    /// Our week starts Monday; `Calendar` starts Sunday.
    static var today: Weekday {
        let index = (Calendar.current.component(.weekday, from: Date()) + 5) % 7
        return week[index]
    }
}
