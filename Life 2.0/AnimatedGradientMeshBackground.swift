import SwiftUI

struct AnimatedGradientMeshBackground: View {

    private struct Blob {
        let color1: Color
        let color2: Color
        let speed: Double
        let xAmplitude: CGFloat
        let yAmplitude: CGFloat
        let phase: Double
        let radiusFactor: CGFloat
    }

    private let blobs: [Blob] = [
        Blob(color1: .blue,   color2: .purple, speed: 0.03,  xAmplitude: 0.30, yAmplitude: 0.28, phase: 0.0,  radiusFactor: 0.9),
        Blob(color1: .pink,   color2: .orange, speed: 0.025, xAmplitude: 0.35, yAmplitude: 0.20, phase: 1.3,  radiusFactor: 0.8),
        Blob(color1: .mint,   color2: .teal,   speed: 0.02,  xAmplitude: 0.22, yAmplitude: 0.32, phase: 2.7,  radiusFactor: 0.95),
        Blob(color1: .yellow, color2: .red,    speed: 0.018, xAmplitude: 0.18, yAmplitude: 0.26, phase: 4.1,  radiusFactor: 0.75)
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let maxDimension = max(size.width, size.height)

                context.fill(Path(rect), with: .color(Color.black))

                for blob in blobs {
                    let localT = t * blob.speed + blob.phase

                    let centerX = size.width  * 0.5 + cos(localT)        * blob.xAmplitude * size.width
                    let centerY = size.height * 0.5 + sin(localT * 0.9) * blob.yAmplitude * size.height

                    let radius = maxDimension * blob.radiusFactor

                    let circleRect = CGRect(
                        x: centerX - radius,
                        y: centerY - radius,
                        width: radius * 2,
                        height: radius * 2
                    )

                    let gradient = Gradient(colors: [blob.color1, blob.color2])

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