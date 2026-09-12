import SwiftUI

@main
struct RepQApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @State private var store = GymStore()
    @State private var tab = Tab.today

    /// How often the floor advances, so waits stay honest.
    private let tickInterval: TimeInterval = 15

    enum Tab: String, CaseIterable {
        case today, week, floor

        var title: String {
            switch self {
            case .today: "TODAY"
            case .week: "MY WEEK"
            case .floor: "FLOOR"
            }
        }

        var symbol: String {
            switch self {
            case .today: "target"
            case .week: "calendar"
            case .floor: "mappin.and.ellipse"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Group {
                switch tab {
                case .today: TodayView(store: store)
                case .week: ScheduleView(store: store)
                case .floor: FloorView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            tabBar
        }
        .background(
            LinearGradient(colors: [Color(hex: "1A2030"), Style.bg],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        )
        .background(Style.bg.ignoresSafeArea())
        .onReceive(Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()) { _ in
            guard tab != .week else { return } // don't yank the UI mid-edit
            store.tick()
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 0) {
                Text("rep").foregroundStyle(Style.text)
                Text("Q").foregroundStyle(Style.accent)
            }
            .font(.system(size: 21, weight: .heavy))

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Style.free)
                    .frame(width: 7, height: 7)
                Text("\(store.others.count + 1) IN GYM")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.4)
                    .foregroundStyle(Style.muted)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Style.surface, in: Capsule())
            .overlay(Capsule().stroke(Style.line, lineWidth: 1))
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    private var tabBar: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { item in
                Button { tab = item } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol).font(.system(size: 17))
                        Text(item.title)
                            .font(.system(size: 10.5, weight: .heavy))
                            .tracking(0.4)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(tab == item ? Style.accent : Style.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 9)
        .padding(.horizontal, 12)
        .background(Style.bg.opacity(0.92))
        .overlay(Rectangle().fill(Style.line).frame(height: 1), alignment: .top)
    }
}
