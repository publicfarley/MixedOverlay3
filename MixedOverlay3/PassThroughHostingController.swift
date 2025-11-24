import SwiftUI

/// A custom UIHostingController that wraps its view in a PassThroughView to allow
/// touches to pass through transparent areas of the SwiftUI content to underlying UIKit views.
class PassThroughHostingController<Content: View>: UIHostingController<Content> {
    private var passThroughView: PassThroughView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false
    }

    /// Embeds this hosting controller's view in a PassThroughView within the given parent.
    /// This setup allows touches on transparent SwiftUI areas to pass through to views underneath.
    /// - Parameter parent: The parent view to embed this controller's view in
    /// - Parameter delegateHitTestTo: Optional view to delegate hit-testing to when transparent areas are touched
    func embedInPassThroughView(in parent: UIView, delegateHitTestTo: UIView? = nil) {
        let wrapper = PassThroughView(delegateHitTestTo: delegateHitTestTo)
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.backgroundColor = .clear
        wrapper.isOpaque = false

        parent.addSubview(wrapper)
        wrapper.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            wrapper.topAnchor.constraint(equalTo: parent.topAnchor),
            wrapper.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            wrapper.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            wrapper.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            view.topAnchor.constraint(equalTo: wrapper.topAnchor),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])

        passThroughView = wrapper
    }
}

/// A custom UIView that overrides hit-testing to allow touches to pass through
/// transparent areas while still capturing touches on opaque SwiftUI content.
///
/// Uses pixel-based alpha detection to determine if touches land on visible SwiftUI content
/// or transparent pass-through areas. When a transparent area is detected, delegates
/// hit-testing to the specified UIView (typically the underlying UIKit layer).
private class PassThroughView: UIView {
    private var encounteredEvents = Set<UIEvent>()
    private var cachedHitResults = [ObjectIdentifier: UIView]()
    private weak var delegateHitTestTo: UIView?

    init(delegateHitTestTo: UIView? = nil) {
        super.init(frame: .zero)
        self.delegateHitTestTo = delegateHitTestTo
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            encounteredEvents.removeAll()
            cachedHitResults.removeAll()
            return nil
        }

        guard let event else {
            return super.hitTest(point, with: nil)
        }

        let eventId = ObjectIdentifier(event)

        // Handle iOS 18+ double hit-test behavior: on second call for same event, return cached result
        if encounteredEvents.contains(event) {
            let cachedResult = cachedHitResults[eventId]
            encounteredEvents.removeAll()
            cachedHitResults.removeAll()
            return cachedResult
        }

        // Use pixel-based alpha detection for all cases (self, hosting view, or any other view)
        if isPointOnOpaqueContent(point, in: hitView) {
            // Touch is on visible content - let the hit view handle it
            encounteredEvents.insert(event)
            cachedHitResults[eventId] = hitView
            return hitView
        }

        // Touch is on transparent area - delegate to underlying layer
        encounteredEvents.insert(event)
        if let delegateView = delegateHitTestTo {
            let delegatePoint = delegateView.convert(point, from: self)
            let delegateResult = delegateView.hitTest(delegatePoint, with: event)
            if let result = delegateResult {
                cachedHitResults[eventId] = result
            }
            return delegateResult
        }
        return nil
    }

    /// Determines if a point is on opaque (visible) content by sampling the pixel alpha.
    /// - Parameters:
    ///   - point: The point in this view's coordinate system
    ///   - targetView: The view to render and sample
    /// - Returns: true if the point is on content with alpha > threshold, false if transparent
    private func isPointOnOpaqueContent(_ point: CGPoint, in targetView: UIView) -> Bool {
        let pointInTargetView = targetView.convert(point, from: self)

        // Ensure point is within bounds
        guard targetView.bounds.contains(pointInTargetView) else {
            return false
        }

        // Create a bitmap context to render a single pixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData: [UInt8] = [0, 0, 0, 0] // RGBA

        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }

        // Translate context to render the sample point at origin
        context.translateBy(x: -pointInTargetView.x, y: -pointInTargetView.y)

        // Render the target view's layer into our context
        targetView.layer.render(in: context)

        // Check alpha channel (index 3 in RGBA)
        let alpha = pixelData[3]
        let alphaThreshold: UInt8 = 10 // Small threshold to account for anti-aliasing

        return alpha > alphaThreshold
    }
}
