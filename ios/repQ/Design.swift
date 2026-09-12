import SwiftUI

enum Style {
    static let bg = Color(hex: "0B0D11")
    static let surface = Color(hex: "151922")
    static let surfaceLift = Color(hex: "1D222D")
    static let line = Color(hex: "272D3A")
    static let text = Color(hex: "F3F5F8")
    static let muted = Color(hex: "8A94A6")
    static let accent = Color(hex: "C6F24E")
    static let accentInk = Color(hex: "12160C")
    static let busy = Color(hex: "FF5F56")
    static let free = Color(hex: "38D07A")

    static let cardRadius: CGFloat = 18
    static let heroRadius: CGFloat = 26
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

/// Small uppercase label above a heading.
struct Eyebrow: View {
    let text: String
    var tint: Color = Style.muted

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy))
            .tracking(1.6)
            .foregroundStyle(tint)
    }
}

/// One of the three figures under the Next Up card.
struct StatTile: View {
    let value: String
    let label: String
    var highlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .heavy))
                .foregroundStyle(highlighted ? Style.accent : Style.text)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.7)
                .foregroundStyle(Style.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 11)
        .background(Style.surface, in: RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Style.line, lineWidth: 1))
    }
}

/// A figure inside the lime Next Up card.
struct HeroChip: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 15, weight: .heavy))
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.6)
                .opacity(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 11)
        .background(Style.accentInk.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(Style.accentInk)
    }
}

struct MovedBadge: View {
    var body: some View {
        Text("MOVED UP")
            .font(.system(size: 9, weight: .heavy))
            .tracking(0.6)
            .foregroundStyle(Style.accent)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Style.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Style.surface, in: RoundedRectangle(cornerRadius: Style.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Style.cardRadius)
                    .stroke(Style.line, lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
