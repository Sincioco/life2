import SwiftUI

struct GradientMeshBackground: View {

    private struct Blob {
        let colors: [Color]
        let speed: Double
        let xAmplitude: CGFloat
        let yAmplitude: CGFloat
        let phase: Double
        let radiusFactor: CGFloat
    }

    private let blobs: [Blob] = [
        Blob(colors: [.pink, .purple, .blue], speed: 0.025, xAmplitude: 0.30, yAmplitude: 0.26, phase: 0.0, radiusFactor: 0.9),
        Blob(colors: [.orange, .red, .yellow], speed: 0.020, xAmplitude: 0.35, yAmplitude: 0.22, phase: 1.8, radiusFactor: 0.8),
        Blob(colors: [.mint, .teal, .cyan], speed: 0.018, xAmplitude: 0.24, yAmplitude: 0.34, phase: 3.1, radiusFactor: 1.0),
        Blob(colors: [.indigo, .blue, .cyan], speed: 0.015, xAmplitude: 0.18, yAmplitude: 0.28, phase: 4.4, radiusFactor: 0.85)
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let maxDimension = max(size.width, size.height)

                context.fill(Path(rect), with: .color(.black))

                for blob in blobs {
                    let localT = t * blob.speed + blob.phase

                    let centerX = size.width * 0.5 + CGFloat(cos(localT)) * blob.xAmplitude * size.width
                    let centerY = size.height * 0.5 + CGFloat(sin(localT * 0.9)) * blob.yAmplitude * size.height

                    let radius = maxDimension * blob.radiusFactor
                    let circleRect = CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2)

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
            .blur(radius: 80)
            .ignoresSafeArea()
        }
    }
}
