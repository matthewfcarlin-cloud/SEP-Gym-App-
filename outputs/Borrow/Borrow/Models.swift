import Foundation
import Observation

struct Equipment: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let category: String
    let symbol: String
    let rate: Int
    let detail: String
    let contents: String

    static let catalog = [
        Equipment(id: "BR-001", name: "Cordless drill", category: "Workshop", symbol: "powerdrill.fill", rate: 12, detail: "A little power for your next big idea. A compact 18V drill with two speeds and everything you need to get started.", contents: "18V drill · 2 batteries · charger · 12 bits"),
        Equipment(id: "BR-002", name: "Adventure tent", category: "Outdoors", symbol: "tent.fill", rate: 18, detail: "Your home away from home. A lightweight, weather-ready tent with room for two and an easy setup.", contents: "2-person tent · poles · stakes · rainfly"),
        Equipment(id: "BR-003", name: "Weekend camera", category: "Creative", symbol: "camera.fill", rate: 28, detail: "Make the everyday worth remembering. A mirrorless camera kit ready for portraits, trips, and your next creative project.", contents: "Camera · 35mm lens · battery · 64GB card")
    ]

    static func resolve(_ payload: String) -> Equipment? {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        if let item = catalog.first(where: { $0.id.caseInsensitiveCompare(trimmed) == .orderedSame }) { return item }
        guard let url = URL(string: trimmed), url.scheme == "borrow", url.host == "equipment" else { return nil }
        return catalog.first { url.path == "/\($0.id)" }
    }
}

enum RentalPeriod: Int, CaseIterable, Identifiable {
    case day = 1, weekend = 3, week = 7
    var id: Int { rawValue }
    var title: String { switch self { case .day: "1 day"; case .weekend: "3 days"; case .week: "1 week" } }
    func total(for item: Equipment) -> Int { item.rate * rawValue }
}

struct Rental: Identifiable, Codable {
    let id: UUID
    let equipment: Equipment
    let startedAt: Date
    let dueAt: Date
    let days: Int
    let total: Int
    var returnedAt: Date?
    var isActive: Bool { returnedAt == nil }
}

enum RentalError: LocalizedError {
    case alreadyRented
    var errorDescription: String? { "This item is already in your rentals. Return it before borrowing it again." }
}

@MainActor @Observable final class RentalStore {
    private(set) var rentals: [Rental] = []
    private let defaults: UserDefaults
    private let key = "borrow.demo.rentals.v1"
    var active: [Rental] { rentals.filter(\.isActive) }
    var history: [Rental] { rentals.filter { !$0.isActive } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key), let saved = try? JSONDecoder().decode([Rental].self, from: data) { rentals = saved }
    }

    func isAvailable(_ equipment: Equipment) -> Bool { !active.contains { $0.equipment.id == equipment.id } }

    @discardableResult func rent(_ equipment: Equipment, period: RentalPeriod, now: Date = Date()) throws -> Rental {
        guard isAvailable(equipment) else { throw RentalError.alreadyRented }
        let rental = Rental(id: UUID(), equipment: equipment, startedAt: now,
                            dueAt: Calendar.current.date(byAdding: .day, value: period.rawValue, to: now)!,
                            days: period.rawValue, total: period.total(for: equipment))
        rentals.insert(rental, at: 0)
        save()
        return rental
    }

    func returnItem(_ id: UUID) {
        guard let index = rentals.firstIndex(where: { $0.id == id && $0.isActive }) else { return }
        rentals[index].returnedAt = Date()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(rentals) { defaults.set(data, forKey: key) }
    }
}
