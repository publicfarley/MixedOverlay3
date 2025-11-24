import SwiftUI
import UIKit

/// The parent view controller that manages both Layer B (UIKit bottom) and Layer A (SwiftUI overlay top).
/// This controller demonstrates a mixed architecture where touches can selectively pass through
/// the SwiftUI overlay to interact with UIKit controls underneath.
class MainContainerViewController: UIViewController {
    private var layerBController: LayerBViewController?
    private var overlayHostingController: PassThroughHostingController<OverlayView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayers()
    }

    private func setupLayers() {
        // Layer B: Add UIKit view controller at the bottom
        let layerB = LayerBViewController()
        addChild(layerB)
        view.addSubview(layerB.view)
        layerB.view.frame = view.bounds
        layerB.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layerB.didMove(toParent: self)
        layerBController = layerB

        // Layer A: Add SwiftUI overlay on top with pass-through touch handling
        let overlayView = OverlayView()
        let hostingController = PassThroughHostingController(rootView: overlayView)

        addChild(hostingController)
        hostingController.view.backgroundColor = .clear
        hostingController.view.isOpaque = false

        // Embed the hosting controller's view in a PassThroughView
        // Pass Layer B's view so that hits in transparent areas delegate to Layer B
        // This maintains the responder chain for all UIKit controls and gesture recognizers
        hostingController.embedInPassThroughView(in: view, delegateHitTestTo: layerB.view)

        hostingController.didMove(toParent: self)
        overlayHostingController = hostingController
    }
}
