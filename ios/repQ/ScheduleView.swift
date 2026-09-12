import SwiftUI

struct ScheduleView: View {
    @Bindable var store: GymStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 1")
                    Text("Your week")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(Style.text)
                    Text("Tap a day to set what you're training. We handle the machine order.")
                        .font(.system(size: 13.5))
                        .foregroundStyle(Style.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

                ForEach(Weekday.week) { day in
                    DayRow(
                        day: day,
                        split: store.split(on: day),
                        isToday: day.id == store.today.id,
                        isEditing: store.editingDay == day.id,
                        onTap: { withAnimation(.snappy(duration: 0.22)) { store.toggleEditor(for: day) } }
                    )

                    if store.editingDay == day.id {
                        SplitPicker(
                            selected: store.split(on: day),
                            onPick: { split in
                                withAnimation(.snappy(duration: 0.22)) { store.assign(split: split, to: day) }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

struct DayRow: View {
    let day: Weekday
    let split: Split
    let isToday: Bool
    let isEditing: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                Text(day.short)
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(0.4)
                    .foregroundStyle(split.isRest ? Style.muted : Style.accentInk)
                    .frame(width: 42, height: 42)
                    .background(
                        split.isRest ? Style.surfaceLift : Color(hex: split.colorHex),
                        in: RoundedRectangle(cornerRadius: 12)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(split.name)
                            .font(.system(size: 15.5, weight: .bold))
                            .foregroundStyle(Style.text)
                        if isToday {
                            Text("TODAY")
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(0.6)
                                .foregroundStyle(Style.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Style.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    Text(split.tag)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Style.muted)
                }

                Spacer(minLength: 0)
                Image(systemName: isEditing ? "xmark" : "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Style.muted)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .card()
        }
        .buttonStyle(.plain)
    }
}

struct SplitPicker: View {
    let selected: Split
    let onPick: (Split) -> Void

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Split.catalog) { split in
                Button { onPick(split) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(split.name)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundStyle(Style.text)
                        Text(split.tag)
                            .font(.system(size: 10.5))
                            .foregroundStyle(Style.muted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(13)
                    .background(
                        selected.id == split.id ? Style.accent.opacity(0.08) : Style.surface,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selected.id == split.id ? Style.accent : Style.line, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }
}
