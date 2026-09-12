import SwiftUI

@main struct BorrowApp: App {
    @State private var store = RentalStore()
    var body: some Scene {
        WindowGroup { AppView().environment(store).preferredColorScheme(.light) }
    }
}

enum AppTab: Hashable { case discover, rentals }
enum AppSheet: String, Identifiable {
    case scan
    var id: String { rawValue }
}

struct AppView: View {
    @State private var tab: AppTab = .discover
    @State private var sheet: AppSheet?
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { DiscoverView { sheet = .scan } }
                .tabItem { Label("Discover", systemImage: "square.grid.2x2") }.tag(AppTab.discover)
            NavigationStack { RentalsView() }
                .tabItem { Label("My rentals", systemImage: "bag") }.tag(AppTab.rentals)
        }
        .tint(BorrowStyle.ink)
        .sheet(item: $sheet) { _ in
            ScanView { tab = .rentals }.presentationDragIndicator(.visible)
        }
    }
}

struct DiscoverView: View {
    @Environment(RentalStore.self) private var store
    let onScan: () -> Void
    @State private var category = "All gear"
    private let categories = ["All gear", "Workshop", "Outdoors", "Creative"]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .center) {
                    Text("borrow.").font(.system(size: 32, weight: .heavy, design: .rounded)).tracking(-1.5)
                    Spacer()
                    Text("DEMO").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.5)
                        .padding(.horizontal, 12).padding(.vertical, 8).background(BorrowStyle.sand, in: Capsule())
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label("THE NEIGHBORHOOD WORKSHOP", systemImage: "location.fill")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(1.2).foregroundStyle(BorrowStyle.muted)
                    Text("Big plans.\nBorrow the gear.").font(.system(size: 39, weight: .semibold, design: .serif)).tracking(-1.7).lineSpacing(-3)
                    Text("Less owning. More doing.").font(.system(size: 16)).foregroundStyle(BorrowStyle.muted)
                }
                Button(action: onScan) {
                    HStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("See it. Scan it.\nMake it happen.").font(.system(size: 24, weight: .semibold)).tracking(-0.5).multilineTextAlignment(.leading)
                            HStack(spacing: 6) { Text("Scan QR or tap NFC"); Image(systemName: "arrow.right") }.font(.system(size: 12, weight: .medium)).foregroundStyle(BorrowStyle.lime)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "qrcode.viewfinder").font(.system(size: 62, weight: .ultraLight)).foregroundStyle(BorrowStyle.lime)
                    }.padding(25).frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white).background(BorrowStyle.ink, in: RoundedRectangle(cornerRadius: 27))
                }.buttonStyle(.plain).accessibilityIdentifier("scanEquipment")
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Text("Good gear, close by").font(.system(size: 21, weight: .semibold)).tracking(-0.6); Spacer(); Text("3 items").font(.system(size: 12)).foregroundStyle(BorrowStyle.muted) }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { option in
                                Button { category = option } label: {
                                    Text(option).font(.system(size: 12, weight: .medium)).padding(.horizontal, 16).padding(.vertical, 11)
                                        .background(category == option ? BorrowStyle.ink : .white.opacity(0.6), in: Capsule())
                                        .foregroundStyle(category == option ? .white : BorrowStyle.ink)
                                }.buttonStyle(.plain).accessibilityAddTraits(category == option ? .isSelected : [])
                            }
                        }
                    }
                    ForEach(Equipment.catalog.filter { category == "All gear" || $0.category == category }) { item in
                        NavigationLink { EquipmentDetailView(item: item) } label: { EquipmentRow(item: item) }.buttonStyle(.plain)
                    }
                }
                HStack(spacing: 8) { Image(systemName: "arrow.triangle.2.circlepath"); Text("Shared gear. Bigger possibilities.") }.font(.system(size: 12)).foregroundStyle(BorrowStyle.muted).frame(maxWidth: .infinity).padding(.vertical, 8)
            }.padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 24)
        }.pageBackground().toolbar(.hidden, for: .navigationBar)
    }
}

#Preview { AppView().environment(RentalStore()) }
