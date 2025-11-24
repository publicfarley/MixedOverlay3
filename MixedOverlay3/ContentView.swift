//
//  ContentView.swift
//  MixedOverlay3
//
//  Created by Farley Caesar on 2025-11-23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainContainerViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

/// A UIViewControllerRepresentable that bridges the UIKit MainContainerViewController
/// into the SwiftUI view hierarchy.
struct MainContainerViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MainContainerViewController {
        MainContainerViewController()
    }

    func updateUIViewController(_ uiViewController: MainContainerViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    ContentView()
}
