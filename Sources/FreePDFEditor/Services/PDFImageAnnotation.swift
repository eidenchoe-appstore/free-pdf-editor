import AppKit
import CoreText
import PDFKit

final class PDFImageAnnotation: PDFAnnotation {
    private let image: NSImage

    init(image: NSImage, bounds: CGRect) {
        self.image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
        color = .clear
        isReadOnly = false
        shouldDisplay = true
        shouldPrint = true
        setValue("image-signature" as NSString, forAnnotationKey: PDFAnnotationKey(rawValue: "/FPEType"))
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        context.saveGState()
        context.interpolationQuality = .high
        context.draw(cgImage, in: bounds)
        context.restoreGState()
    }
}

final class PDFTextStampAnnotation: PDFAnnotation {
    private let label: String
    private let stampColor: NSColor

    init(label: String, color: NSColor, bounds: CGRect) {
        self.label = label
        self.stampColor = color
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
        self.color = color
        shouldDisplay = true
        shouldPrint = true
        isReadOnly = false
        setValue("text-stamp" as NSString, forAnnotationKey: PDFAnnotationKey(rawValue: "/FPEType"))
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        let rect = bounds.insetBy(dx: 2, dy: 2)
        context.saveGState()

        context.setFillColor(stampColor.withAlphaComponent(0.08).cgColor)
        context.addPath(CGPath(roundedRect: rect, cornerWidth: 5, cornerHeight: 5, transform: nil))
        context.fillPath()

        context.addPath(CGPath(roundedRect: rect, cornerWidth: 5, cornerHeight: 5, transform: nil))
        context.setStrokeColor(stampColor.cgColor)
        context.setLineWidth(2.2)
        context.strokePath()

        let fontSize = min(18, rect.height * 0.45)
        let font = CTFontCreateWithName("HelveticaNeue-CondensedBold" as CFString, fontSize, nil)
        let attrs: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: stampColor.cgColor
        ]
        let attributed = CFAttributedStringCreate(nil, label as CFString, attrs as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attributed)
        let lineBounds = CTLineGetBoundsWithOptions(line, [])
        context.textMatrix = .identity
        context.textPosition = CGPoint(
            x: rect.midX - lineBounds.width / 2,
            y: rect.midY - lineBounds.height / 2 - lineBounds.origin.y
        )
        CTLineDraw(line, context)
        context.restoreGState()
    }
}
