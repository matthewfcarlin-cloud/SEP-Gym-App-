import Foundation
import Observation

/// Deterministic pseudo-random, so relaunching doesn't reshuffle the whole gym.
private struct SeededRandom {
    private var value: UInt64
    init(seed: UInt64) { self.value = seed }

    mutating func next() -> Double {
        value = (value &* 1103515245 &+ 12345) % 2147483648
        return Double(value) / 2147483648
    }
}

@Observable
final class GymStore {
    private static let storageKey = "repq.schedule.v1"
    private static let otherMemberCount = 9
    private static let occupancyChance = 0.45
    /// Other members are mid-workout, not starting fresh — they have at most
    /// this many exercises left. Routing all of them as full sessions ahead of
    /// the user gridlocks the floor and leaves the user permanently last.
    private static let maxRemainingExercises = 6
    private static let maxArrivalSpread = 12.0
    private static let seed: UInt64 = 20260912

    private static let defaultSchedule = [
        "mon": "push", "tue": "pull", "wed": "legs", "thu": "rest",
        "fri": "upper", "sat": "lower", "sun": "rest",
    ]

    private(set) var schedule: [String: String]
    private(set) var occupancy: Scheduler.Ledger
    private(set) var completed: [String] = []
    private(set) var others: [Member]
    var editingDay: String?

    let today = Weekday.today

    init() {
        self.schedule = Self.loadSchedule()
        var random = SeededRandom(seed: Self.seed)
        self.occupancy = Self.makeOccupancy(&random)
        self.others = Self.makeMembers(&random)
    }

    // MARK: - Derived

    var todaysSplit: Split {
        Split.byID[schedule[today.id] ?? "rest"] ?? .rest
    }

    var remainingExercises: [String] {
        todaysSplit.exercises.filter { !completed.contains($0) }
    }

    var plan: SessionPlan {
        Scheduler.planFloor(
            occupancy: occupancy,
            others: others,
            userExercises: remainingExercises
        )
    }

    var openStationCount: Int {
        occupancy.values.reduce(0) { $0 + $1.filter { $0 == 0 }.count }
    }

    var totalStationCount: Int {
        Machine.catalog.reduce(0) { $0 + $1.stations }
    }

    func openStations(for machine: Machine) -> Int {
        (occupancy[machine.id] ?? []).filter { $0 == 0 }.count
    }

    func split(on day: Weekday) -> Split {
        Split.byID[schedule[day.id] ?? "rest"] ?? .rest
    }

    // MARK: - Actions

    func assign(split: Split, to day: Weekday) {
        schedule[day.id] = split.id
        completed = []
        editingDay = nil
        Self.saveSchedule(schedule)
    }

    func toggleEditor(for day: Weekday) {
        editingDay = editingDay == day.id ? nil : day.id
    }

    func complete(_ machineID: String) {
        guard !completed.contains(machineID) else { return }
        completed.append(machineID)
        // Finishing frees the station you were using.
        occupancy[machineID] = (occupancy[machineID] ?? []).map { _ in 0 }
    }

    /// A member scanned on or off this station. This is the hook the QR scanner
    /// calls into — see `scanOn`/`scanOff` below.
    func toggleStation(machine: Machine, index: Int) {
        guard var stations = occupancy[machine.id], stations.indices.contains(index) else { return }
        stations[index] = stations[index] > 0 ? 0 : Double(machine.minutes)
        occupancy[machine.id] = stations
    }

    /// Called when someone scans the QR code on a machine and starts using it.
    func scanOn(machineID: String, station: Int) {
        guard let machine = Machine.byID[machineID],
              var stations = occupancy[machineID],
              stations.indices.contains(station - 1) else { return }
        stations[station - 1] = Double(machine.minutes)
        occupancy[machineID] = stations
    }

    /// Called when they scan off, or their session times out.
    func scanOff(machineID: String, station: Int) {
        guard var stations = occupancy[machineID],
              stations.indices.contains(station - 1) else { return }
        stations[station - 1] = 0
        occupancy[machineID] = stations
    }

    func restart() {
        completed = []
        var random = SeededRandom(seed: Self.seed)
        occupancy = Self.makeOccupancy(&random)
    }

    /// The floor keeps moving, so waits stay honest.
    func tick() {
        occupancy = occupancy.mapValues { $0.map { max(0, $0 - 1) } }
    }

    // MARK: - Seeding

    private static func makeOccupancy(_ random: inout SeededRandom) -> Scheduler.Ledger {
        Machine.catalog.reduce(into: Scheduler.Ledger()) { ledger, machine in
            ledger[machine.id] = (0..<machine.stations).map { _ in
                random.next() < occupancyChance ? (random.next() * Double(machine.minutes)).rounded() : 0
            }
        }
    }

    private static func makeMembers(_ random: inout SeededRandom) -> [Member] {
        let trainable = Split.catalog.filter { !$0.isRest }
        return (0..<otherMemberCount).map { index in
            let split = trainable[Int(random.next() * Double(trainable.count)) % trainable.count]
            // They started before you, so the early compounds are behind them.
            let left = 1 + Int(random.next() * Double(maxRemainingExercises))
            return Member(
                id: "member-\(index)",
                exercises: Array(split.exercises.suffix(left)),
                arrivesIn: (random.next() * maxArrivalSpread).rounded()
            )
        }
    }

    // MARK: - Persistence

    private static func loadSchedule() -> [String: String] {
        guard let saved = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] else {
            return defaultSchedule
        }
        return defaultSchedule.merging(saved) { _, stored in stored }
    }

    private static func saveSchedule(_ schedule: [String: String]) {
        UserDefaults.standard.set(schedule, forKey: storageKey)
    }
}
