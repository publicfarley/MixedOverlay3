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
/// Handles both iOS 16-25 (subview-based detection) and iOS 26+ (layer-based detection).
/// iOS 26 made the SwiftUI view hierarchy opaque to UIKit, requiring layer hit-testing instead.
///
/// When a transparent area is detected, delegates hit-testing to the specified UIView
/// (typically the underlying UIKit view) to maintain the responder chain integrity.
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

        // iOS 26+: SwiftUI hosting view captures all touches, we need layer-based pixel detection
        // to determine if the touch is on transparent vs opaque SwiftUI content
        if #available(iOS 26, *) {
            if isHostingRootView(hitView) {
                // Check if point is on opaque SwiftUI content using layer rendering
                if isPointOnOpaqueContent(point, in: hitView) {
                    // Touch is on actual SwiftUI content (toolbar, FAB, etc.) - let SwiftUI handle it
                    encounteredEvents.insert(event)
                    cachedHitResults[eventId] = hitView
                    return hitView
                }

                // Touch is on transparent area - delegate to Layer B
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
        }

        // If the hit view is this container itself (transparent area), delegate or pass through
        if hitView == self {
            if let delegateView = delegateHitTestTo {
                let delegatePoint = delegateView.convert(point, from: self)
                let delegateResult = delegateView.hitTest(delegatePoint, with: event)
                encounteredEvents.insert(event)
                if let result = delegateResult {
                    cachedHitResults[eventId] = result
                }
                return delegateResult
            }
            return nil
        }

        // Pre-iOS 26: Check if hit view is the hosting view root using class name
        if !ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)
        ) {
            if isHostingRootView(hitView) {
                if let delegateView = delegateHitTestTo {
                    let delegatePoint = delegateView.convert(point, from: self)
                    let delegateResult = delegateView.hitTest(delegatePoint, with: event)
                    encounteredEvents.insert(event)
                    if let result = delegateResult {
                        cachedHitResults[eventId] = result
                    }
                    return delegateResult
                }
                return nil
            }
        }

        // iOS 18+: Mark event as processed and cache result for double hit-test handling
        if #available(iOS 18, *) {
            encounteredEvents.insert(event)
            cachedHitResults[eventId] = hitView
        }

        // Touch landed on actual SwiftUI content - handle normally
        return hitView
    }

    /// Checks if the given view is the UIHostingController's root view.
    /// The hosting view's class name contains "_UIHostingView".
    /// This works for both iOS 16+ and iOS 26+ to detect transparent hosting areas.
    private func isHostingRootView(_ view: UIView) -> Bool {
        let className = String(describing: type(of: view))
        return className.contains("_UIHostingView")
    }

    /// Determines if a point is on opaque (visible) SwiftUI content by sampling the pixel alpha.
    /// This is necessary for iOS 26+ where SwiftUI's view hierarchy is opaque to UIKit hit-testing.
    /// - Parameters:
    ///   - point: The point in this view's coordinate system
    ///   - hostingView: The hosting view to render and sample
    /// - Returns: true if the point is on content with alpha > threshold, false if transparent
    private func isPointOnOpaqueContent(_ point: CGPoint, in hostingView: UIView) -> Bool {
        let pointInHostingView = hostingView.convert(point, from: self)

        // Ensure point is within bounds
        guard hostingView.bounds.contains(pointInHostingView) else {
            return false
        }

        // Render a small region around the point and check alpha
        let sampleSize: CGFloat = 1
        let sampleRect = CGRect(
            x: pointInHostingView.x - sampleSize / 2,
            y: pointInHostingView.y - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )

        // Create a bitmap context to render into
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
        context.translateBy(x: -sampleRect.origin.x, y: -sampleRect.origin.y)

        // Render the hosting view's layer into our context
        hostingView.layer.render(in: context)

        // Check alpha channel (index 3 in RGBA)
        let alpha = pixelData[3]
        let alphaThreshold: UInt8 = 10 // Small threshold to account for anti-aliasing

        return alpha > alphaThreshold
    }
}
