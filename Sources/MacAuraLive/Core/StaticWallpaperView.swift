import AppKit
import Foundation

public class StaticWallpaperView: NSView {
    private var imageURL: URL
    private var originalImage: NSImage?
    private var currentPlacement: String = "fit"
    private var currentZoom: Double = 1.0
    
    public init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor
        loadImage()
        applyPlacement()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadImage() {
        if let img = NSImage(contentsOf: imageURL) {
            self.originalImage = img
            self.needsDisplay = true
        }
    }
    
    public func setPlacement(placement: String, zoom: Double = 1.0) {
        self.currentPlacement = placement
        self.currentZoom = zoom
        self.needsDisplay = true
    }
    
    private func applyPlacement() {
        self.currentPlacement = AppSettings.shared.wallpaperPlacement
        self.currentZoom = AppSettings.shared.wallpaperZoom
        self.needsDisplay = true
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Fill background with solid black
        NSColor.black.setFill()
        dirtyRect.fill()
        
        guard let img = originalImage else { return }
        let imgSize = img.size
        guard imgSize.width > 0 && imgSize.height > 0 else { return }
        
        let viewRect = self.bounds
        guard viewRect.width > 0 && viewRect.height > 0 else { return }
        
        var targetRect = NSRect.zero
        
        switch currentPlacement {
        case "original", "center":
            // 1:1 Native Original Resolution (Actual pixels, centered, no zoom/stretch)
            let w = imgSize.width
            let h = imgSize.height
            let x = (viewRect.width - w) / 2.0
            let y = (viewRect.height - h) / 2.0
            targetRect = NSRect(x: x, y: y, width: w, height: h)
            
        case "fit":
            // Aspect Fit - Preserves original proportions without cropping
            let scale = min(viewRect.width / imgSize.width, viewRect.height / imgSize.height)
            let w = imgSize.width * scale
            let h = imgSize.height * scale
            let x = (viewRect.width - w) / 2.0
            let y = (viewRect.height - h) / 2.0
            targetRect = NSRect(x: x, y: y, width: w, height: h)
            
        case "fill":
            // Aspect Fill - Fills display, cropping if necessary while preserving aspect ratio
            let scale = max(viewRect.width / imgSize.width, viewRect.height / imgSize.height)
            let w = imgSize.width * scale
            let h = imgSize.height * scale
            let x = (viewRect.width - w) / 2.0
            let y = (viewRect.height - h) / 2.0
            targetRect = NSRect(x: x, y: y, width: w, height: h)
            
        case "zoom":
            // Custom Zoom Level based on Aspect Fit
            let baseScale = min(viewRect.width / imgSize.width, viewRect.height / imgSize.height)
            let finalScale = baseScale * CGFloat(max(0.25, min(3.0, currentZoom)))
            let w = imgSize.width * finalScale
            let h = imgSize.height * finalScale
            let x = (viewRect.width - w) / 2.0
            let y = (viewRect.height - h) / 2.0
            targetRect = NSRect(x: x, y: y, width: w, height: h)
            
        case "stretch":
            // Stretch to fill screen axes independently
            targetRect = viewRect
            
        default:
            // Default to Original Resolution (1:1 Actual Pixels)
            let w = imgSize.width
            let h = imgSize.height
            let x = (viewRect.width - w) / 2.0
            let y = (viewRect.height - h) / 2.0
            targetRect = NSRect(x: x, y: y, width: w, height: h)
        }
        
        NSGraphicsContext.current?.imageInterpolation = .high
        img.draw(in: targetRect, from: NSRect(origin: .zero, size: imgSize), operation: .sourceOver, fraction: 1.0)
    }
}
