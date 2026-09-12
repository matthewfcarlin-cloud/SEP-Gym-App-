import AppKit
import CoreImage
let root = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: root.appendingPathComponent("SampleTags"), withIntermediateDirectories: true)
for id in ["BR-001", "BR-002", "BR-003"] {
    let filter = CIFilter(name: "CIQRCodeGenerator")!
    filter.setValue(Data("borrow://equipment/\(id)".utf8), forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")
    let output = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 16, y: 16))
    let image = CIContext().createCGImage(output, from: output.extent)!
    let rep = NSBitmapImageRep(cgImage: image)
    try rep.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("SampleTags/\(id).png"))
}
let image = NSImage(size: NSSize(width: 1260, height: 1000))
image.lockFocus()
NSColor(calibratedRed: 0.90, green: 0.92, blue: 0.87, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0,y: 0,width: 1260,height: 1000)).fill()
for (index,name) in ["01-discover", "02-scan", "03-equipment"].enumerated() {
    let screen = NSImage(contentsOf: root.appendingPathComponent("Previews/\(name).png"))!
    let rect = NSRect(x: 35 + index * 415, y: 76, width: 360, height: 784)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: 32, yRadius: 32).addClip()
    screen.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
    let labels = ["01  DISCOVER", "02  SCAN OR TAP", "03  BORROW"]
    (labels[index] as NSString).draw(at: NSPoint(x: 35 + index*415, y: 32), withAttributes: [.font:NSFont.monospacedSystemFont(ofSize: 16, weight:.medium), .foregroundColor:NSColor(calibratedRed:0.10,green:0.19,blue:0.17,alpha:1)])
}
("borrow." as NSString).draw(at: NSPoint(x:35,y:901),withAttributes:[.font:NSFont.systemFont(ofSize:46,weight:.heavy),.foregroundColor:NSColor(calibratedRed:0.10,green:0.19,blue:0.17,alpha:1)])
("Less owning. More doing.     /     iOS demo" as NSString).draw(at:NSPoint(x:670,y:920),withAttributes:[.font:NSFont.systemFont(ofSize:20,weight:.regular),.foregroundColor:NSColor.darkGray])
image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("Previews/borrow-preview.png"))
