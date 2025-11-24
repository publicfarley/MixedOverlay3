import SwiftUI

/// Layer A: The SwiftUI overlay that sits on top of the UIKit Layer B.
/// This view covers the entire screen but has a transparent middle section
/// that allows touches to pass through to Layer B underneath.
struct OverlayView: View {
    @State private var fabTapped = false

    var body: some View {
        ZStack {
            // Transparent background - allows touches to pass through
            Color.clear
                .allowsHitTesting(true)

            VStack(spacing: 0) {
                // Top toolbar - interactive, captures touches
                HStack {
                    Button(action: { }) {
                        Image(systemName: "arrowtriangle.left.fill")
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Mixed Overlay")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.3, blue: 0.5),
                            Color(red: 0.1, green: 0.2, blue: 0.4),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Spacer()
                    .allowsHitTesting(false)

                // Bottom floating action button - interactive, captures touches
                VStack {
                    HStack {
                        Spacer()

                        Button(action: { fabTapped.toggle() }) {
                            Image(systemName: fabTapped ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.8, green: 0.2, blue: 0.2),
                                                    Color(red: 0.6, green: 0.1, blue: 0.1),
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(radius: 5)
                                )
                        }
                        .padding(20)
                    }
                }
                .allowsHitTesting(true)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OverlayView()
}
