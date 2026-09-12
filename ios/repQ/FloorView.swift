import SwiftUI

struct FloorView: View {
    @Bindable var store: GymStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Live floor")
                    Text("\(store.openStationCount) of \(store.totalStationCount) open")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(Style.text)
                    Text("Fed by QR scan-ins at each machine. Tap a station to simulate a member scanning on or off — your route reorders instantly.")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Style.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

                ForEach(Machine.catalog) { machine in
                    MachineRow(
                        machine: machine,
                        stations: store.occupancy[machine.id] ?? [],
                        onToggle: { index in
                            Haptics.tap()
                            withAnimation(.snappy(duration: 0.2)) {
                                store.toggleStation(machine: machine, index: index)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

struct MachineRow: View {
    let machine: Machine
    let stations: [Double]
    let onToggle: (Int) -> Void

    private var openCount: Int { stations.filter { $0 == 0 }.count }

    private var subtitle: String {
        guard openCount == 0 else { return "\(openCount) of \(machine.stations) open" }
        let soonest = Int((stations.min() ?? 0).rounded())
        return "All busy · free in ~\(soonest) min"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: machine.symbol)
                .font(.system(size: 18))
                .foregroundStyle(openCount == 0 ? Style.busy : Style.accent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(machine.name)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundStyle(Style.text)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Style.muted)
            }

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                ForEach(Array(stations.enumerated()), id: \.offset) { index, minutes in
                    Button { onToggle(index) } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(minutes > 0 ? Style.busy : Style.free)
                            .frame(width: 9, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 13)
        .card()
    }
}
