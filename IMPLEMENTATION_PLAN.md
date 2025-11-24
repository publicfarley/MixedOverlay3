# Mixed UIKit/SwiftUI Overlay Implementation Plan

## Overview

Build an iOS application demonstrating a mixed UIKit and SwiftUI architecture with advanced touch event handling. The core challenge is implementing touch pass-through from a full-screen SwiftUI overlay to UIKit controls underneath.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│              MainContainerViewController                │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │        PassThroughHostingController               │  │  ← Layer A (Top)
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │           OverlayView (SwiftUI)             │  │  │
│  │  │  ┌─────────────────────────────────────┐    │  │  │
│  │  │  │           Top Toolbar               │    │  │  │  ← Interactive
│  │  │  └─────────────────────────────────────┘    │  │  │
│  │  │                                             │  │  │
│  │  │           (Transparent Area)                │  │  │  ← Touches pass through
│  │  │                                             │  │  │
│  │  │  ┌─────────────────────────────────────┐    │  │  │
│  │  │  │      Floating Action Button         │    │  │  │  ← Interactive
│  │  │  └─────────────────────────────────────┘    │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │           LayerBViewController (UIKit)            │  │  ← Layer B (Bottom)
│  │                                                   │  │
│  │              ┌─────────────┐                      │  │
│  │              │  UIButton   │                      │  │  ← Interactive
│  │              └─────────────┘                      │  │
│  │              ┌─────────────┐                      │  │
│  │              │  UILabel    │                      │  │
│  │              └─────────────┘                      │  │
│  │                                                   │  │
│  │           (Distinct Background Color)             │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Files to Create

| File | Purpose |
|------|---------|
| `PassThroughHostingController.swift` | Custom UIHostingController with touch pass-through logic |
| `LayerBViewController.swift` | Bottom UIKit layer with interactive controls |
| `OverlayView.swift` | SwiftUI overlay with toolbar and FAB |
| `MainContainerViewController.swift` | Parent controller managing both layers |

## Files to Modify

| File | Changes |
|------|---------|
| `ContentView.swift` | Bridge to present MainContainerViewController via UIViewControllerRepresentable |

## Technical Approach

### The Core Problem

`UIHostingController` captures all touches within its bounds by default, even in transparent areas. This is because:

1. The hosting controller creates an internal `UIView` with `isUserInteractionEnabled = true`
2. UIKit's hit-testing finds this view before reaching views underneath
3. SwiftUI's internal structure doesn't expose "empty" vs "content" distinction to UIKit

### The Solution: Custom Hit-Testing

Override `hitTest(_:with:)` in a wrapper view to selectively pass touches through:

```swift
class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }

        // If touch lands on the container or hosting root view (transparent area)
        // return nil to pass the touch to views underneath
        if hitView == self || isHostingRootView(hitView) {
            return nil
        }

        // Touch landed on actual SwiftUI content - handle normally
        return hitView
    }

    private func isHostingRootView(_ view: UIView) -> Bool {
        let className = String(describing: type(of: view))
        return className.contains("_UIHostingView")
    }
}
```

### Why This Works

1. **Default behavior**: `super.hitTest()` traverses the view hierarchy and returns the deepest view containing the touch point
2. **Pass-through check**: If the returned view is the hosting controller's root view (meaning no SwiftUI content was hit), we return `nil`
3. **Content interaction**: If actual SwiftUI elements (buttons, toolbar) were hit, we return the hit view normally
4. **UIKit receives touches**: When we return `nil`, UIKit continues hit-testing down the view hierarchy to Layer B

## Implementation Order

1. **PassThroughHostingController.swift** - Foundation for the solution
2. **LayerBViewController.swift** - UIKit content layer
3. **OverlayView.swift** - SwiftUI overlay content
4. **MainContainerViewController.swift** - Assembles the layers
5. **ContentView.swift** - Integration with SwiftUI app entry point
6. **Build & Verify** - Compile both app and test targets

## Constraints Addressed

| Constraint | Solution |
|------------|----------|
| SwiftUI layer must cover full screen | OverlayView uses full-screen layout with VStack/Spacer |
| SwiftUI layer must not block touches in empty space | PassThroughView returns `nil` for transparent areas |
| Visible SwiftUI elements must remain interactive | hitTest returns the hit view when SwiftUI content is tapped |
| Standard UIHostingController blocks all touches | Custom PassThroughHostingController with wrapper view |
