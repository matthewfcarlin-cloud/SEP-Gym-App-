// Builds the RepQ app icon from the brand logo.
// Usage: swift brand/make_icon.swift <source.png> <out.png> <x> <y> <w> <h> <inset%>
//
// Note: this composites an existing image rather than drawing shapes. An earlier
// version drew the mark by hand with NSBezierPath and produced a black square —
// strokes painted but fills silently did not. Drawing straight through CGContext
// and CGImage avoids AppKit's colour/context conversion entirely.
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 8,
      let cropX = Double(arguments[3]), let cropY = Double(arguments[4]),
      let cropW = Double(arguments[5]), let cropH = Double(arguments[6]),
      let insetPercent = Double(arguments[7]) else {
    fatalError("usage: make_icon.swift <source> <out> <x> <y> <w> <h> <inset%>")
}

let side = 1024.0
let source = URL(fileURLWithPath: arguments[1])
let output = URL(fileURLWithPath: arguments[2])

guard let data = try? Data(contentsOf: source),
      let rep = NSBitmapImageRep(data: data),
      let full = rep.cgImage else { fatalError("Could not read \(source.path)") }

guard let mark = full.cropping(to: CGRect(x: cropX, y: cropY, width: cropW, height: cropH)) else {
    fatalError("Crop rect lies outside the source image")
}

// noneSkipLast: opaque output with no alpha channel, which App Store icons
// require, and unlike a no-alpha NSBitmapImageRep it actually backs a context.
guard let context = CGContext(
    data: nil, width: Int(side), height: Int(side),
    bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("Could not create icon context") }

context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: side, height: side))

// Fit the mark inside the safe area, preserving its aspect ratio.
let available = side * (1 - insetPercent * 2)
let scale = min(available / cropW, available / cropH)
let drawnWidth = cropW * scale
let drawnHeight = cropH * scale
context.draw(mark, in: CGRect(
    x: (side - drawnWidth) / 2,
    y: (side - drawnHeight) / 2,
    width: drawnWidth,
    height: drawnHeight
))

guard let image = context.makeImage(),
      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}
try png.write(to: output)
print("wrote \(output.lastPathComponent)")
