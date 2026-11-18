#!/usr/bin/swift
// Draws the app icon and writes Resources/AppIcon.icns.
// Usage: swift scripts/make-icon.swift [output.icns] [preview.png]

import AppKit
import CoreGraphics

/// Draws the icon on a 1024-point canvas with the origin in the lower left corner:
/// a dark plate, like a menu bar, with two icons and the outlined gap between them.
func drawIcon(in ctx: CGContext) {
    let plate = CGRect(x: 100, y: 100, width: 824, height: 824)
    let platePath = CGPath(roundedRect: plate, cornerWidth: 185, cornerHeight: 185, transform: nil)
    let space = CGColorSpaceCreateDeviceRGB()

    func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }

    // Soft shadow under the plate.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0, 0, 0, 0.30))
    ctx.addPath(platePath)
    ctx.setFillColor(color(0.12, 0.15, 0.30))
    ctx.fillPath()
    ctx.restoreGState()

    // The plate, lighter at the top.
    ctx.saveGState()
    ctx.addPath(platePath)
    ctx.clip()
    let night = CGGradient(
        colorsSpace: space,
        colors: [color(0.24, 0.30, 0.56), color(0.09, 0.11, 0.24)] as CFArray,
        locations: [0, 1])!
    ctx.drawLinearGradient(
        night, start: CGPoint(x: 0, y: plate.maxY), end: CGPoint(x: 0, y: plate.minY), options: [])
    ctx.restoreGState()

    // Two icons, one on each side.
    ctx.setFillColor(color(1, 1, 1, 0.96))
    for x in [CGFloat(262), CGFloat(762)] {
        ctx.fillEllipse(in: CGRect(x: x - 74, y: 512 - 74, width: 148, height: 148))
    }

    // The gap between them, shown with its frame.
    let gap = CGRect(x: 384, y: 412, width: 256, height: 200)
    let gapPath = CGPath(roundedRect: gap, cornerWidth: 56, cornerHeight: 56, transform: nil)
    ctx.addPath(gapPath)
    ctx.setFillColor(color(1, 1, 1, 0.10))
    ctx.fillPath()
    ctx.addPath(gapPath)
    ctx.setStrokeColor(color(0.62, 0.78, 1.00))
    ctx.setLineWidth(24)
    ctx.setLineCap(.round)
    ctx.setLineDash(phase: 0, lengths: [38, 44])
    ctx.strokePath()
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    ctx.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    drawIcon(in: ctx)
    return rep.representation(using: .png, properties: [:])!
}

let arguments = CommandLine.arguments
let output = arguments.count > 1 ? arguments[1] : "Resources/AppIcon.icns"
let fm = FileManager.default
let iconset = fm.temporaryDirectory.appendingPathComponent("AppIcon-\(UUID().uuidString).iconset")
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? fm.removeItem(at: iconset) }

for (name, pixels) in [
    ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
] {
    try png(pixels: pixels).write(to: iconset.appendingPathComponent("\(name).png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", "-o", output, iconset.path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else {
    FileHandle.standardError.write(Data("iconutil failed\n".utf8))
    exit(1)
}
print("Wrote \(output)")

if arguments.count > 2 {
    try png(pixels: 512).write(to: URL(fileURLWithPath: arguments[2]))
    print("Wrote \(arguments[2])")
}
