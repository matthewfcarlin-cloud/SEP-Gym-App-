import SwiftUI

struct EquipmentDetailView: View {
    @Environment(RentalStore.self) private var store
    let item: Equipment
    var onFinished: (() -> Void)?
    @State private var period: RentalPeriod = .day
    @State private var rental: Rental?
    @State private var error: String?
    @State private var showCheckout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ZStack(alignment: .topLeading) {
                    EquipmentArt(equipment: item).frame(height: 240)
                    Label(store.isAvailable(item) ? "Ready to borrow" : "In your rentals", systemImage: "circle.fill")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(BorrowStyle.green)
                        .padding(11).background(.white.opacity(0.85), in: Capsule()).padding(16)
                }.background(BorrowStyle.sand.opacity(0.6), in: RoundedRectangle(cornerRadius: 27))
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(title: "\(item.category) / \(item.id)")
                    Text(item.name).font(.system(size: 33, weight: .semibold, design: .serif)).tracking(-1)
                    Text(item.detail).font(.system(size: 15)).foregroundStyle(BorrowStyle.muted).lineSpacing(4)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Make time for your project").font(.system(size: 17, weight: .semibold))
                    HStack(spacing: 9) {
                        ForEach(RentalPeriod.allCases) { option in
                            Button { period = option } label: {
                                VStack(spacing: 8) {
                                    Text(option.title).font(.system(size: 14, weight: .semibold))
                                    Text("$\(option.total(for: item))").font(.system(size: 22, weight: .semibold, design: .rounded))
                                }.frame(maxWidth: .infinity).padding(.vertical, 18)
                                    .background(period == option ? BorrowStyle.lime : .white, in: RoundedRectangle(cornerRadius: 18))
                                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(period == option ? BorrowStyle.ink : .clear, lineWidth: 1.5))
                            }.buttonStyle(.plain).accessibilityAddTraits(period == option ? .isSelected : [])
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 11) {
                    Label("All the essentials, included", systemImage: "shippingbox").font(.system(size: 15, weight: .semibold))
                    Text(item.contents).font(.system(size: 14)).foregroundStyle(BorrowStyle.muted)
                    Divider()
                    Label("Pick up & return at the workshop", systemImage: "mappin.and.ellipse").font(.system(size: 14))
                }.padding(18).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))
                Text("Demo rental • no payment will be taken.").font(.system(size: 12)).foregroundStyle(BorrowStyle.muted).frame(maxWidth: .infinity)
            }.padding(24)
        }
        .pageBackground().navigationTitle("The details").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                HStack { Text("Total for \(period.title)").foregroundStyle(BorrowStyle.muted); Spacer(); Text("$\(period.total(for: item))").font(.system(size: 25, weight: .semibold)) }
                PrimaryButton(title: store.isAvailable(item) ? "Borrow this item" : "Already borrowed", symbol: "arrow.right") { showCheckout = true }
                    .disabled(!store.isAvailable(item)).opacity(store.isAvailable(item) ? 1 : 0.5)
            }.padding(.horizontal, 24).padding(.vertical, 16).background(BorrowStyle.cream)
        }
        .confirmationDialog("Confirm your demo rental", isPresented: $showCheckout, titleVisibility: .visible) {
            Button("Confirm \(period.title) · $\(period.total(for: item))") {
                do { rental = try store.rent(item, period: period) } catch { self.error = error.localizedDescription }
            }
        } message: { Text("Your rental starts now. No payment will be taken.") }
        .sheet(item: $rental) { rental in RentalSuccessView(rental: rental, onFinished: onFinished).presentationDragIndicator(.visible) }
        .alert("Couldn't start rental", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
    }
}

struct RentalSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    let rental: Rental
    var onFinished: (() -> Void)?
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Image(systemName: "checkmark").font(.system(size: 42, weight: .light)).frame(width: 100, height: 100).background(BorrowStyle.lime, in: Circle()).padding(.top, 45)
                VStack(spacing: 12) {
                    Eyebrow(title: "You're all set")
                    Text("Go make\nsomething great.").font(.system(size: 38, weight: .medium, design: .serif)).tracking(-1.2).multilineTextAlignment(.center)
                    Text("Your \(rental.equipment.name.lowercased()) is ready.\nPick it up at the neighborhood workshop.").font(.system(size: 15)).foregroundStyle(BorrowStyle.muted).multilineTextAlignment(.center).lineSpacing(4)
                }
                VStack(spacing: 18) {
                    EquipmentRow(item: rental.equipment)
                    HStack { Text("Return by"); Spacer(); Text(rental.dueAt, format: .dateTime.month(.abbreviated).day().hour().minute()).fontWeight(.semibold) }
                    Divider()
                    HStack { Text("Demo total"); Spacer(); Text("$\(rental.total)").fontWeight(.semibold) }
                }.font(.system(size: 14)).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 25))
                PrimaryButton(title: onFinished == nil ? "Done" : "View my rentals", symbol: "bag") { dismiss(); onFinished?() }
                Text("This is a demo. No charge was made.").font(.system(size: 12)).foregroundStyle(BorrowStyle.muted)
            }.padding(24)
        }.pageBackground()
    }
}

struct RentalsView: View {
    @Environment(RentalStore.self) private var store
    @State private var returnCandidate: Rental?
    @State private var showHistory = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Eyebrow(title: "Yours for a little while")
                Text("My rentals").font(.system(size: 38, weight: .medium, design: .serif)).tracking(-1.3)
                Picker("Rental status", selection: $showHistory) { Text("Active (\(store.active.count))").tag(false); Text("Returned").tag(true) }.pickerStyle(.segmented)
                let items = showHistory ? store.history : store.active
                if items.isEmpty {
                    VStack(spacing: 17) {
                        Image(systemName: showHistory ? "checkmark.seal" : "bag").font(.system(size: 48, weight: .ultraLight)).padding(.bottom, 8)
                        Text(showHistory ? "Full circle." : "Your next project awaits.").font(.system(size: 25, weight: .medium, design: .serif))
                        Text(showHistory ? "Returned equipment will appear here." : "Find a little inspiration in Discover, or scan a tag to start borrowing.").font(.system(size: 15)).foregroundStyle(BorrowStyle.muted).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 70)
                }
                ForEach(items) { rental in
                    VStack(alignment: .leading, spacing: 17) {
                        EquipmentRow(item: rental.equipment)
                        HStack { Label(rental.isActive ? "Return by" : "Returned", systemImage: rental.isActive ? "clock" : "checkmark.circle"); Spacer(); Text(rental.returnedAt ?? rental.dueAt, format: .dateTime.month(.abbreviated).day()).fontWeight(.semibold) }.font(.system(size: 14))
                        Text("\(rental.days) day rental · $\(rental.total) demo total").font(.system(size: 12)).foregroundStyle(BorrowStyle.muted)
                        if rental.isActive {
                            PrimaryButton(title: "Return equipment", symbol: "arrow.uturn.backward") { returnCandidate = rental }
                        }
                    }.padding(16).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 26))
                }
            }.padding(24)
        }.pageBackground().toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Return this equipment?", isPresented: Binding(get: { returnCandidate != nil }, set: { if !$0 { returnCandidate = nil } }), titleVisibility: .visible) {
            Button("Confirm demo return") { if let rental = returnCandidate { store.returnItem(rental.id) }; returnCandidate = nil }
        } message: { Text("This simulates returning the item to the workshop and makes it available to borrow again.") }
    }
}
