import Foundation

/// One stop on a routed session.
struct PlannedStep: Identifiable, Hashable {
    let id = UUID()
    let machine: Machine
    /// 1-based station number, so the UI can say "go to rack 3".
    let station: Int
    let startsAt: Double
    let endsAt: Double
    let wait: Double
    /// Where this exercise sat in the user's untouched training order.
    let plannedIndex: Int

    var wasMovedUp: Bool { plannedIndex > 0 }
}

struct SessionPlan {
    let steps: [PlannedStep]
    let totalWait: Int
    let minutesSaved: Int
    let finishesAt: Int
    let othersRouted: Int

    static let empty = SessionPlan(steps: [], totalWait: 0, minutesSaved: 0, finishesAt: 0, othersRouted: 0)
}

/// Another member training right now, with their own planned session.
struct Member: Identifiable, Hashable {
    let id: String
    let exercises: [String]
    /// Minutes from now until they start.
    let arrivesIn: Double
}

/*
 The gym is modelled as a reservation ledger: every machine owns N stations, and
 each station carries the minute-offset at which it next becomes free. Live QR
 scan-ins seed that ledger with real occupancy.

 Routing is greedy with a lookahead cost. At each step we pick the remaining
 exercise that minimises `wait + (planned_position * priorityWeight)`, so a
 session is only reordered when skipping ahead saves more time than the training
 cost of pushing a heavy compound later.

 Every member is routed through the same shared ledger, so one person's
 reservation is another person's blocked slot. Nobody is ever sent to a station
 that someone else is already walking towards.
*/
enum Scheduler {
    /// Minutes of waiting we'll tolerate to keep the planned training order.
    static let priorityWeight = 2.2
    /// An exercise can only jump this many places forward, so a heavy lift is
    /// never stranded at the very end of a session.
    static let maxReorderDrift = 3

    /// machineID -> minutes-until-free, one entry per station. 0 means open now.
    typealias Ledger = [String: [Double]]

    // MARK: - Ledger

    static func makeLedger(occupancy: Ledger) -> Ledger {
        Machine.catalog.reduce(into: Ledger()) { ledger, machine in
            let busy = occupancy[machine.id] ?? []
            ledger[machine.id] = (0..<machine.stations).map { index in
                index < busy.count ? busy[index] : 0
            }
        }
    }

    static func earliestFree(_ ledger: Ledger, _ machineID: String) -> Double {
        ledger[machineID]?.min() ?? .infinity
    }

    static func firstFreeStation(_ ledger: Ledger, _ machineID: String) -> Int {
        guard let stations = ledger[machineID], let soonest = stations.min() else { return 0 }
        return stations.firstIndex(of: soonest) ?? 0
    }

    /// Returns a new ledger with `machineID` booked from `startAt` for `duration`.
    static func reserve(_ ledger: Ledger, _ machineID: String, startAt: Double, duration: Double) -> Ledger {
        guard let stations = ledger[machineID] else { return ledger }
        let slot = firstFreeStation(ledger, machineID)
        var updated = ledger
        updated[machineID] = stations.enumerated().map { index, free in
            index == slot ? startAt + duration : free
        }
        return updated
    }

    // MARK: - Routing

    private struct Candidate {
        let machineID: String
        let plannedIndex: Int
    }

    private struct RouteResult {
        let steps: [PlannedStep]
        let ledger: Ledger
        let totalWait: Double
        let finishesAt: Double
    }

    private static func cost(wait: Double, plannedIndex: Int, stepIndex: Int) -> Double {
        guard plannedIndex - stepIndex <= maxReorderDrift else { return .infinity }
        return wait + Double(plannedIndex) * priorityWeight
    }

    /// Pick the next exercise: lowest cost, falling back to the planned order
    /// when every remaining option is drift-locked.
    private static func bestCandidate(from remaining: [Candidate], ledger: Ledger,
                                      clock: Double, stepIndex: Int) -> Candidate {
        let scored = remaining.map { candidate -> (candidate: Candidate, cost: Double) in
            let availableAt = max(clock, earliestFree(ledger, candidate.machineID))
            return (candidate, cost(wait: availableAt - clock,
                                    plannedIndex: candidate.plannedIndex,
                                    stepIndex: stepIndex))
        }
        guard let best = scored.min(by: { $0.cost < $1.cost }), best.cost.isFinite else {
            return remaining[0]
        }
        return best.candidate
    }

    /// Route one member's exercises through the shared ledger.
    private static func route(exercises: [String], ledger startLedger: Ledger,
                              startMinute: Double) -> RouteResult {
        var remaining = exercises.enumerated().map { Candidate(machineID: $1, plannedIndex: $0) }
        var ledger = startLedger
        var clock = startMinute
        var steps: [PlannedStep] = []
        var totalWait: Double = 0
        var stepIndex = 0

        while !remaining.isEmpty {
            let choice = bestCandidate(from: remaining, ledger: ledger,
                                       clock: clock, stepIndex: stepIndex)
            remaining.removeAll { $0.machineID == choice.machineID }

            guard let machine = Machine.byID[choice.machineID] else { continue }
            let startsAt = max(clock, earliestFree(ledger, machine.id))
            let duration = Double(machine.minutes)

            steps.append(PlannedStep(
                machine: machine,
                station: firstFreeStation(ledger, machine.id) + 1,
                startsAt: startsAt,
                endsAt: startsAt + duration,
                wait: startsAt - clock,
                plannedIndex: choice.plannedIndex
            ))

            totalWait += startsAt - clock
            ledger = reserve(ledger, machine.id, startAt: startsAt, duration: duration)
            clock = startsAt + duration
            stepIndex += 1
        }

        return RouteResult(steps: steps, ledger: ledger, totalWait: totalWait, finishesAt: clock)
    }

    /// Cost of simply working top-to-bottom, used for the "queue saved" figure.
    private static func naiveWait(exercises: [String], ledger: Ledger, startMinute: Double) -> Double {
        var ledger = ledger
        var clock = startMinute
        var wait: Double = 0

        for id in exercises {
            guard let machine = Machine.byID[id] else { continue }
            let availableAt = max(clock, earliestFree(ledger, id))
            wait += availableAt - clock
            ledger = reserve(ledger, id, startAt: availableAt, duration: Double(machine.minutes))
            clock = availableAt + Double(machine.minutes)
        }
        return wait
    }

    /// Plan the whole floor: route everyone already training, then route the user
    /// around the reservations that leaves behind.
    static func planFloor(occupancy: Ledger, others: [Member], userExercises: [String]) -> SessionPlan {
        guard !userExercises.isEmpty else { return .empty }

        let base = makeLedger(occupancy: occupancy)
        let shared = others.reduce(base) { ledger, member in
            route(exercises: member.exercises, ledger: ledger, startMinute: member.arrivesIn).ledger
        }

        let user = route(exercises: userExercises, ledger: shared, startMinute: 0)
        let naive = naiveWait(exercises: userExercises, ledger: shared, startMinute: 0)

        return SessionPlan(
            steps: user.steps,
            totalWait: Int(user.totalWait.rounded()),
            minutesSaved: max(0, Int((naive - user.totalWait).rounded())),
            finishesAt: Int(user.finishesAt.rounded()),
            othersRouted: others.count
        )
    }
}
