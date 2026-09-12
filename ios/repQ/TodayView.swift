import SwiftUI

struct TodayView: View {
    @Bindable var store: GymStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if store.todaysSplit.isRest {
                    RestDayView()
                } else if let next = store.plan.steps.first {
                    header
                    NextUpCard(step: next, onFinish: { store.complete(next.machine.id) })
                        .padding(.top, 16)
                    statRow.padding(.top, 14)
                    queue.padding(.top, 8)
                } else {
                    SessionDoneView(totalWait: store.plan.totalWait, onRestart: store.restart)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: "\(store.today.name) · \(store.todaysSplit.name) day")
            Text("Your route")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Style.text)
            Text("Ordered around \(store.plan.othersRouted) other members training right now, so you never queue.")
                .font(.system(size: 13.5))
                .foregroundStyle(Style.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statRow: some View {
        HStack(spacing: 9) {
            StatTile(value: "\(store.plan.finishesAt) min", label: "Session length")
            StatTile(value: "\(store.plan.totalWait) min", label: "Total waiting")
            savedTile
        }
    }

    /// With a clear floor there is genuinely nothing to save — say so rather
    /// than rendering a meaningless "−0 min".
    private var savedTile: some View {
        let saved = store.plan.minutesSaved
        return StatTile(
            value: saved > 0 ? "−\(saved) min" : "Clear",
            label: saved > 0 ? "Queue saved" : "No queues",
            highlighted: true
        )
    }

    private var queue: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Then, in order").padding(.top, 18)

            ForEach(Array(store.plan.steps.dropFirst().enumerated()), id: \.element.id) { position, step in
                QueueRow(step: step, position: position + 1)
            }
            ForEach(store.completed, id: \.self) { machineID in
                if let machine = Machine.byID[machineID] {
                    CompletedRow(machine: machine)
                }
            }
        }
    }
}

struct NextUpCard: View {
    let step: PlannedStep
    let onFinish: () -> Void

    private var waitLabel: String {
        step.wait < 1
            ? "Open now · walk straight over"
            : "Free in \(Int(step.wait.rounded())) min · finish your rest here"
    }

    private var doneBy: String {
        Date(timeIntervalSinceNow: step.endsAt * 60)
            .formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: step.wasMovedUp ? "Next up · reordered to skip a queue" : "Next up",
                    tint: Style.accentInk.opacity(0.6))

            HStack(spacing: 14) {
                Image(systemName: step.machine.symbol)
                    .font(.system(size: 32, weight: .semibold))
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.machine.name)
                        .font(.system(size: 27, weight: .heavy))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(waitLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .opacity(0.72)
                }
            }
            .foregroundStyle(Style.accentInk)
            .padding(.top, 9)

            HStack(spacing: 8) {
                HeroChip(value: "#\(step.station)", label: "Station")
                HeroChip(value: "\(step.machine.minutes) min", label: "On machine")
                HeroChip(value: doneBy, label: "Done by")
            }
            .padding(.top, 16)

            Button(action: onFinish) {
                Text("Finished — what's next?")
                    .font(.system(size: 15, weight: .heavy))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Style.accentInk, in: RoundedRectangle(cornerRadius: 15))
                    .foregroundStyle(Style.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Style.accent, Color(hex: "A8DC36")],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: Style.heroRadius)
        )
    }
}

struct QueueRow: View {
    let step: PlannedStep
    let position: Int

    private var startClock: String {
        Date(timeIntervalSinceNow: step.startsAt * 60)
            .formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 13) {
            Text("\(Int(step.startsAt.rounded()))m")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Style.accent)
                .frame(width: 46)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(step.machine.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Style.text)
                    if step.plannedIndex > position { MovedBadge() }
                }
                Text("\(step.wait < 1 ? "No wait" : "\(Int(step.wait.rounded())) min wait") · \(step.machine.minutes) min · \(startClock)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Style.muted)
            }

            Spacer(minLength: 0)
            Image(systemName: step.machine.symbol)
                .font(.system(size: 17))
                .foregroundStyle(Style.muted)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
        .card()
    }
}

struct CompletedRow: View {
    let machine: Machine

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Style.muted)
                .frame(width: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(machine.name)
                    .font(.system(size: 15, weight: .bold))
                    .strikethrough()
                Text("Completed").font(.system(size: 11.5))
            }
            .foregroundStyle(Style.muted)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
        .card()
        .opacity(0.5)
    }
}

struct RestDayView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 38))
                .foregroundStyle(Style.muted)
            Text("Rest day")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Style.text)
            Text("Nothing scheduled — go eat.")
                .font(.system(size: 14))
                .foregroundStyle(Style.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 90)
    }
}

struct SessionDoneView: View {
    let totalWait: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 38))
                .foregroundStyle(Style.accent)
            Text("Session done")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Style.text)
            Text("You waited \(totalWait) minutes total.")
                .font(.system(size: 14))
                .foregroundStyle(Style.muted)
            Button("Start over", action: onRestart)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Style.accent)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 90)
    }
}
