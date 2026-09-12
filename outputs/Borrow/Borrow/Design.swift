import SwiftUI

enum BorrowStyle {
    static let ink = Color(red: 0.10, green: 0.19, blue: 0.17)
    static let green = Color(red: 0.18, green: 0.36, blue: 0.28)
    static let cream = Color(red: 0.97, green: 0.96, blue: 0.92)
    static let muted = Color(red: 0.40, green: 0.44, blue: 0.40)
    static let lime = Color(red: 0.83, green: 0.92, blue: 0.49)
    static let sand = Color(red: 0.91, green: 0.89, blue: 0.82)
}

struct PrimaryButton: View {
    let title: String
    var symbol: String = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title).fontWeight(.semibold); Spacer(); Image(systemName: symbol) }
                .padding(20).foregroundStyle(.white).background(BorrowStyle.ink, in: RoundedRectangle(cornerRadius: 19))
        }.buttonStyle(.plain)
    }
}

struct Eyebrow: View {
    let title: String
    var body: some View { Text(title.uppercased()).font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(BorrowStyle.muted) }
}

struct EquipmentArt: View {
    let equipment: Equipment
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle().stroke(BorrowStyle.ink.opacity(0.07), lineWidth: 1).padding(12)
                Circle().stroke(BorrowStyle.ink.opacity(0.07), lineWidth: 1).padding(36)
                Ellipse().fill(BorrowStyle.ink.opacity(0.10)).frame(width: geometry.size.width * 0.5, height: 13).blur(radius: 9).offset(y: geometry.size.height * 0.32)
                if equipment.id == "BR-001" {
                    DrillDrawing().frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.75).rotationEffect(.degrees(-18))
                } else {
                Image(systemName: equipment.symbol)
                    .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.57, weight: .medium))
                    .foregroundStyle(equipment.id == "BR-001" ? Color(red: 0.80, green: 0.57, blue: 0.20) : BorrowStyle.green)
                    .rotationEffect(.degrees(equipment.id == "BR-001" ? -18 : -8))
                    .shadow(color: BorrowStyle.ink.opacity(0.15), radius: 1, x: 3, y: 5)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.accessibilityHidden(true)
    }
}

struct DrillDrawing: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 200, y: size.height / 180)
            let dark = BorrowStyle.ink
            let gold = Color(red: 0.84, green: 0.60, blue: 0.22)
            func rounded(_ rect: CGRect, _ radius: CGFloat, _ color: Color) {
                context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
            }
            rounded(CGRect(x: 150, y: 34, width: 40, height: 7), 2, .gray)
            rounded(CGRect(x: 125, y: 23, width: 34, height: 30), 5, dark)
            rounded(CGRect(x: 113, y: 19, width: 20, height: 38), 4, .gray)
            var body = Path()
            body.move(to: CGPoint(x: 32, y: 15)); body.addLine(to: CGPoint(x: 105, y: 15))
            body.addQuadCurve(to: CGPoint(x: 118, y: 28), control: CGPoint(x: 118, y: 15))
            body.addLine(to: CGPoint(x: 118, y: 58)); body.addLine(to: CGPoint(x: 80, y: 64))
            body.addLine(to: CGPoint(x: 96, y: 131)); body.addLine(to: CGPoint(x: 58, y: 133))
            body.addLine(to: CGPoint(x: 44, y: 70)); body.addLine(to: CGPoint(x: 27, y: 58))
            body.addQuadCurve(to: CGPoint(x: 32, y: 15), control: CGPoint(x: 14, y: 20)); body.closeSubpath()
            context.fill(body, with: .color(gold))
            rounded(CGRect(x: 48, y: 20, width: 44, height: 23), 5, Color(red: 0.94, green: 0.72, blue: 0.31))
            rounded(CGRect(x: 82, y: 64, width: 16, height: 15), 4, dark)
            var grip = Path()
            grip.move(to: CGPoint(x: 54, y: 76)); grip.addLine(to: CGPoint(x: 71, y: 77)); grip.addLine(to: CGPoint(x: 83, y: 122)); grip.addLine(to: CGPoint(x: 63, y: 124)); grip.closeSubpath()
            context.fill(grip, with: .color(dark))
            rounded(CGRect(x: 49, y: 129, width: 65, height: 28), 6, dark)
            rounded(CGRect(x: 49, y: 132, width: 65, height: 7), 2, gold)
            for y in stride(from: 28, through: 48, by: 7) { rounded(CGRect(x: 30, y: y, width: 11, height: 3), 1, dark.opacity(0.6)) }
        }.accessibilityHidden(true)
    }
}

struct EquipmentRow: View {
    let item: Equipment
    var body: some View {
        HStack(spacing: 15) {
            EquipmentArt(equipment: item).frame(width: 86, height: 86).background(BorrowStyle.sand.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 6) {
                Text(item.category.uppercased()).font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(1.4).foregroundStyle(BorrowStyle.muted)
                Text(item.name).font(.system(size: 17, weight: .semibold)).foregroundStyle(BorrowStyle.ink)
                Text("$\(item.rate) / day").font(.system(size: 14)).foregroundStyle(BorrowStyle.muted)
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right").foregroundStyle(BorrowStyle.ink).font(.system(size: 14))
        }.padding(12).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 24))
    }
}

extension View {
    func pageBackground() -> some View { self.background(BorrowStyle.cream.ignoresSafeArea()).foregroundStyle(BorrowStyle.ink) }
}
