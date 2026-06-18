import AppKit
import SwiftUI

struct SignatureCanvasView: NSViewRepresentable {
    @Binding var signatureImage: NSImage?

    func makeNSView(context: Context) -> SignatureCanvasNSView {
        let view = SignatureCanvasNSView()
        view.onChange = { image in
            signatureImage = image
        }
        return view
    }

    func updateNSView(_ nsView: SignatureCanvasNSView, context: Context) {}
}

final class SignatureCanvasNSView: NSView {
    var onChange: ((NSImage) -> Void)?
    private var strokes: [NSBezierPath] = []
    private var currentStroke = NSBezierPath()

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        layer?.cornerRadius = 8
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.textBackgroundColor.setFill()
        NSBezierPath(rect: bounds).fill()
        NSColor.labelColor.setStroke()
        for stroke in strokes {
            stroke.lineWidth = 2.4
            stroke.lineCapStyle = .round
            stroke.lineJoinStyle = .round
            stroke.stroke()
        }
        currentStroke.lineWidth = 2.4
        currentStroke.lineCapStyle = .round
        currentStroke.lineJoinStyle = .round
        currentStroke.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        currentStroke = NSBezierPath()
        currentStroke.move(to: convert(event.locationInWindow, from: nil))
    }

    override func mouseDragged(with event: NSEvent) {
        currentStroke.line(to: convert(event.locationInWindow, from: nil))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentStroke.line(to: convert(event.locationInWindow, from: nil))
        strokes.append(currentStroke)
        currentStroke = NSBezierPath()
        needsDisplay = true
        onChange?(renderSignature())
    }

    private func renderSignature() -> NSImage {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: max(1, Int(bounds.width * 2)),
            pixelsHigh: max(1, Int(bounds.height * 2)),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        rep.size = bounds.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor.clear.setFill()
        NSBezierPath(rect: bounds).fill()
        NSColor.black.setStroke()
        for stroke in strokes {
            stroke.lineWidth = 2.4
            stroke.lineCapStyle = .round
            stroke.lineJoinStyle = .round
            stroke.stroke()
        }
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
    }
}
