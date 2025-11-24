# Mixed UIKit/SwiftUI Overlay with Touch Pass-Through

## Overview

This project demonstrates a mixed UIKit and SwiftUI architecture with advanced touch event handling. A SwiftUI overlay (Layer A) sits on top of a UIKit view controller (Layer B), with touches passing through transparent SwiftUI areas to reach UIKit controls underneath.

## Architecture

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
│  │              ┌─────────────────┐                  │  │
│  │              │    UIButton     │                  │  │  ← Interactive
│  │              └─────────────────┘                  │  │
│  │              ┌─────────────────┐                  │  │
│  │              │    UILabel      │                  │  │
│  │              └─────────────────┘                  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Files

| File | Purpose |
|------|---------|
| `PassThroughHostingController.swift` | Custom UIHostingController with hit-test delegation logic |
| `LayerBViewController.swift` | UIKit bottom layer with interactive controls |
| `OverlayView.swift` | SwiftUI overlay with toolbar and floating action button |
| `MainContainerViewController.swift` | Parent controller that assembles both layers |
| `ContentView.swift` | SwiftUI bridge using UIViewControllerRepresentable |

## The Core Challenge

`UIHostingController` captures all touches within its bounds by default, even in transparent areas. This prevents touches from reaching UIKit views underneath.

### Constraints Solved

1. SwiftUI layer covers full screen (for layout purposes)
2. SwiftUI layer does not block touches in transparent areas
3. Visible SwiftUI elements (toolbar, FAB) remain interactive
4. Works on both iOS 16 and iOS 26

## Solution: Hit-Test Delegation with Result Caching

### How It Works

The `PassThroughView` overrides `hitTest(_:with:)` to:

1. **Detect transparent areas** - When `super.hitTest()` returns the hosting view itself (`_UIHostingView`), we know the touch landed in a transparent area
2. **Delegate to Layer B** - Convert the touch point to Layer B's coordinate space and call its `hitTest()`
3. **Cache results** - Store the delegated result for the iOS 18+/26 double hit-test mechanism
4. **Return cached result on second call** - iOS 26 calls hitTest twice; the second call must return the same result

### The Critical iOS 26 Fix

iOS 18+ introduced a **double hit-test behavior** where `hitTest` is called twice for the same touch event. The fix:

```swift
// First hit-test call: delegate and cache
let delegateResult = delegateView.hitTest(delegatePoint, with: event)
if let result = delegateResult {
    cachedHitResults[eventId] = result
}
return delegateResult  // Returns UIButton

// Second hit-test call: return cached result
if encounteredEvents.contains(event) {
    let cachedResult = cachedHitResults[eventId]
    return cachedResult  // Returns UIButton (not _UIHostingView)
}
```

Without caching, the second call would return `_UIHostingView` from `super.hitTest()`, breaking touch delivery.

## Compatibility

| iOS Version | Layer A (SwiftUI) | Layer B (UIKit) | Notes |
|-------------|-------------------|-----------------|-------|
| iOS 16 | ✅ | ✅ | Uses class name detection |
| iOS 18 | ✅ | ✅ | Adds double hit-test handling |
| iOS 26 | ✅ | ✅ | Requires result caching for double hit-test |

## Usage

```swift
// In MainContainerViewController
private func setupLayers() {
    // Add Layer B (UIKit) at the bottom
    let layerB = LayerBViewController()
    addChild(layerB)
    view.addSubview(layerB.view)
    layerB.didMove(toParent: self)

    // Add Layer A (SwiftUI) on top with pass-through
    let hostingController = PassThroughHostingController(rootView: OverlayView())
    addChild(hostingController)

    // Key: Pass Layer B's view for hit-test delegation
    hostingController.embedInPassThroughView(in: view, delegateHitTestTo: layerB.view)

    hostingController.didMove(toParent: self)
}
```

## Key Insights

1. **Class name detection works on iOS 26** - Despite iOS 26 making the SwiftUI view hierarchy opaque, checking for `_UIHostingView` in the class name still works for detecting transparent hosting areas

2. **Layer-based detection doesn't work for embedded views** - The Stack Overflow solution using `layer.hitTest(point)?.name == nil` works for `UIWindow` overlays but not for embedded `UIHostingController` views

3. **Coordinate conversion is essential** - When delegating hit-tests, convert the point to the delegate view's coordinate space

4. **Result caching is mandatory for iOS 26** - The double hit-test mechanism requires returning consistent results on both calls
