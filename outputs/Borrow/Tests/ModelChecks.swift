import Foundation

@main struct ModelChecks {
    @MainActor static func main() throws {
        let suite = "borrow.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RentalStore(defaults: defaults)
        let drill = Equipment.catalog[0]
        assert(Equipment.resolve("br-001") == drill)
        assert(Equipment.resolve("borrow://equipment/BR-001") == drill)
        assert(Equipment.resolve("https://untrusted.example/BR-001") == nil)
        assert(Equipment.resolve("BR-999") == nil)
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let rental = try store.rent(drill, period: .weekend, now: start)
        assert(rental.total == 36 && rental.days == 3)
        assert(Calendar.current.dateComponents([.day], from: start, to: rental.dueAt).day == 3)
        assert(!store.isAvailable(drill))
        do { _ = try store.rent(drill, period: .day); assertionFailure("Duplicate rental accepted") } catch RentalError.alreadyRented {} catch { throw error }
        let restored = RentalStore(defaults: defaults)
        assert(restored.active.count == 1 && restored.active[0].id == rental.id)
        restored.returnItem(rental.id)
        restored.returnItem(rental.id)
        assert(restored.active.isEmpty && restored.history.count == 1)
        assert(restored.isAvailable(drill))
        let afterReturn = RentalStore(defaults: defaults)
        assert(afterReturn.history.count == 1 && afterReturn.active.isEmpty)
        _ = try afterReturn.rent(drill, period: .week)
        assert(afterReturn.active[0].total == 84)
        print("PASS: tag resolution, rejection, pricing, due date, duplicate prevention, persistence, return, re-rental")
    }
}
