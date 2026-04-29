import AppKit

enum StatusIcon {
    static func image(active: Bool, connected: Bool) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let tint = active ? NSColor.systemOrange : (connected ? NSColor.labelColor : NSColor.secondaryLabelColor)

        if active {
            NSColor.systemYellow.withAlphaComponent(0.2).setFill()
            NSBezierPath(ovalIn: NSRect(x: 1.7, y: 1.7, width: 18.6, height: 18.6)).fill()
        }

        if let asset = AppResources.image(named: "gong") {
            tint.setFill()
            let iconRect = NSRect(x: 3.8, y: 3.8, width: 14.4, height: 14.4)
            asset.draw(
                in: iconRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1,
                respectFlipped: true,
                hints: nil
            )
            tint.setFill()
            iconRect.fill(using: .sourceAtop)
        }

        if active {
            NSColor.systemOrange.setStroke()
            let ring = NSBezierPath(ovalIn: NSRect(x: 1.7, y: 1.7, width: 18.6, height: 18.6))
            ring.lineWidth = 1.8
            ring.stroke()
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
