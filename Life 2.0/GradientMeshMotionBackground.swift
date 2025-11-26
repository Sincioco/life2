import SwiftUI
import CoreMotion
import Combine

// MARK: - Motion Manager

final class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()

    @Published var pitch: Double = 0   // up / down tilt
    @Published var roll: Double = 0    // left / right tilt

    init() {
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self, let motion else { return }
                self.pitch = motion.attitude.pitch
                self.roll  = motion.attitude.roll
            }
        }
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Gradient Mesh Background with Motion

/// Colorful, slowly-animating gradient mesh background that also responds
/// to how the user tilts the device (gyroscope / CoreMotion).
///
/// Usage:
/// ```swift
/// ZStack {
///     GradientMeshMotionBackground()
///     YourContentHere()
/// }
/// ```
struct GradientMeshMotionBackground: View {

    @StateObject private var motion = MotionManager()

    private struct Blob {
        let colors: [Color]
        let speed: Double          // animation speed
        let xAmplitude: CGFloat    // movement as a fraction of width
        let yAmplitude: CGFloat    // movement as a fraction of height
        let phase: Double          // initial phase offset
        let radiusFactor: CGFloat
        let parallaxFactor: CGFloat // how much device tilt affects this blob
    }

    // Hues of green, orange, yellow
    private let blobs: [Blob] = [
        Blob(
            colors: [
                Color(hue: 0.13, saturation: 0.9, brightness: 0.95), // warm yellow
                Color(hue: 0.10, saturation: 0.8, brightness: 1.0),  // yellow-orange
                Color(hue: 0.14, saturation: 0.7, brightness: 1.0)   // golden
            ],
            speed: 0.020,
            xAmplitude: 0.30,
            yAmplitude: 0.26,
            phase: 0.0,
            radiusFactor: 0.95,
            parallaxFactor: 1.0
        ),
        Blob(
            colors: [
                Color(hue: 0.33, saturation: 0.8, brightness: 0.9),  // vivid green
                Color(hue: 0.28, saturation: 0.9, brightness: 0.9),  // yellow-green
                Color(hue: 0.24, saturation: 0.8, brightness: 0.95)  // lime-ish
            ],
            speed: 0.018,
            xAmplitude: 0.34,
            yAmplitude: 0.30,
            phase: 1.7,
            radiusFactor: 1.05,
            parallaxFactor: 1.4
        ),
        Blob(
            colors: [
                Color(hue: 0.08, saturation: 0.9, brightness: 0.95), // orange
                Color(hue: 0.05, saturation: 0.8, brightness: 0.95),
                Color(hue: 0.10, saturation: 0.7, brightness: 1.0)
            ],
            speed: 0.016,
            xAmplitude: 0.22,
            yAmplitude: 0.32,
            phase: 3.0,
            radiusFactor: 0.9,
            parallaxFactor: 0.8
        ),
        Blob(
            colors: [
                Color(hue: 0.37, saturation: 0.8, brightness: 0.9),  // cooler green
                Color(hue: 0.32, saturation: 0.7, brightness: 0.9),
                Color(hue: 0.28, saturation: 0.7, brightness: 0.95)
            ],
            speed: 0.014,
            xAmplitude: 0.26,
            yAmplitude: 0.28,
            phase: 4.4,
            radiusFactor: 1.1,
            parallaxFactor: 1.8
        )
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            // Normalize tilt to a reasonable range for parallax (in points)
            let tiltX = CGFloat(motion.roll)          // left/right
            let tiltY = CGFloat(motion.pitch)         // up/down
            let baseParallax: CGFloat = 120           // global parallax scale

            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let maxDimension = max(size.width, size.height)

                // Soft dark base
                context.fill(
                    Path(rect),
                    with: .color(Color(.sRGB, red: 0.03, green: 0.05, blue: 0.03, opacity: 1.0))
                )

                for blob in blobs {
                    let localT = t * blob.speed + blob.phase

                    // Time-based movement
                    let animX = CGFloat(cos(localT)) * blob.xAmplitude * size.width
                    let animY = CGFloat(sin(localT * 0.9)) * blob.yAmplitude * size.height

                    // Device tilt parallax
                    let parallaxX = tiltX * baseParallax * blob.parallaxFactor
                    let parallaxY = tiltY * baseParallax * blob.parallaxFactor

                    let centerX = size.width * 0.5 + animX + parallaxX
                    let centerY = size.height * 0.5 + animY + parallaxY

                    let radius = maxDimension * blob.radiusFactor

                    let circleRect = CGRect(
                        x: centerX - radius,
                        y: centerY - radius,
                        width: radius * 2,
                        height: radius * 2
                    )

                    let gradient = Gradient(colors: blob.colors)

                    context.fill(
                        Path(ellipseIn: circleRect),
                        with: .radialGradient(
                            gradient,
                            center: CGPoint(x: centerX, y: centerY),
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                }
            }
            // Heavy blur so overlapping blobs become a smooth mesh
            .blur(radius: 90)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GradientMeshMotionBackground()

        VStack(spacing: 12) {
            Text("Gradient Mesh + Motion")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("Tilt your device to gently shift the colors.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding()
    }
}
