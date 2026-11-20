// Builds a non-template icon set from a black silhouette: the silhouette with a white outline,
// so the icon stays visible over any menu bar color and inside the input-source badge.
//
// Usage: swift tools/outline-icon.swift <source.png> <output.iconset>
// Then:  iconutil -c icns <output.iconset> -o <icon.icns>
//
// The outline width is computed per output size (about 1/22 of the icon, and never under 1 px),
// so it stays visible at 16 px in the menu bar without swallowing the thin parts of the silhouette. Each size is drawn at 4x and
// scaled down for smooth edges.

import AppKit
import CoreImage

let args = CommandLine.arguments
guard args.count == 3, let source = NSImage(contentsOfFile: args[1]),
      let sourceCG = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("usage: outline-icon <source.png> <output.iconset>"); exit(1)
}
let outDir = URL(fileURLWithPath: args[2])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let context = CIContext()

func render(size: Int) -> CGImage {
    let scale = 4
    let canvas = size * scale
    let outline = max(1.0, Double(size) / 22) * Double(scale)
    let inset = Int(outline.rounded(.up))   // just enough room for the outline

    // The silhouette, centered and shrunk to leave room for the outline.
    let cg = CGContext(data: nil, width: canvas, height: canvas, bitsPerComponent: 8, bytesPerRow: 0,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    cg.interpolationQuality = .high
    cg.draw(sourceCG, in: CGRect(x: inset, y: inset, width: canvas - 2 * inset, height: canvas - 2 * inset))
    let silhouette = CIImage(cgImage: cg.makeImage()!)

    // White outline: grow the silhouette's shape, then paint it white.
    let grown = silhouette.applyingFilter("CIMorphologyMaximum", parameters: [kCIInputRadiusKey: outline])
    let white = grown.applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        "inputBiasVector": CIVector(x: 1, y: 1, z: 1, w: 0),
    ])
    // CIColorMatrix works on unpremultiplied color, so this keeps the grown alpha and sets color to white.
    let combined = silhouette.composited(over: white)
        .cropped(to: CGRect(x: 0, y: 0, width: canvas, height: canvas))
        .applyingFilter("CILanczosScaleTransform", parameters: [kCIInputScaleKey: 1.0 / Double(scale)])
    return context.createCGImage(combined, from: CGRect(x: 0, y: 0, width: size, height: size))!
}

// The sizes an .iconset needs: name -> pixel size.
let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in sizes {
    let rep = NSBitmapImageRep(cgImage: render(size: px))
    try rep.representation(using: .png, properties: [:])!.write(to: outDir.appendingPathComponent(name + ".png"))
}
print("wrote \(sizes.count) images to \(outDir.path)")
