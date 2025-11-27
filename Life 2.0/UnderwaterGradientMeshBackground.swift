import SwiftUI

/// Underwater-style animated gradient mesh background.
/// - Colors: underwater blues/teals, bright upper-right, darker lower-left.
/// - Motion: slow, wave-like drift.
struct UnderwaterGradientMeshBackground: View {
    
    // One "blob" in the mesh
    private struct Blob {
        let colors: [Color]
        let speed: Double          // animation speed
        let xAmplitude: CGFloat    // movement as a fraction of width
        let yAmplitude: CGFloat    // movement as a fraction of height
        let phase: Double          // phase offset
        let radiusFactor: CGFloat
        let bias: CGPoint          // positional bias (0–1 in each axis)
    }
    
    // Underwater palette: deep blue, teal, cyan, a hint of light caustics
    private let blobs: [Blob] = [
        Blob(
            colors: [
                Color(hue: 0.56, saturation: 0.75, brightness: 0.95),  // bright cyan-blue
                Color(hue: 0.54, saturation: 0.70, brightness: 0.85),
                Color(hue: 0.53, saturation: 0.65, brightness: 0.90)
            ],
            speed: 0.010,
            xAmplitude: 0.22,
            yAmplitude: 0.18,
            phase: 0.0,
            radiusFactor: 1.1,
            bias: CGPoint(x: 0.75, y: 0.20) // upper-right-ish
        ),
        Blob(
            colors: [
                Color(hue: 0.55, saturation: 0.85, brightness: 0.80),  // teal
                Color(hue: 0.53, saturation: 0.80, brightness: 0.75),
                Color(hue: 0.50, saturation: 0.80, brightness: 0.70)
            ],
            speed: 0.009,
            xAmplitude: 0.26,
            yAmplitude: 0.22,
            phase: 1.7,
            radiusFactor: 1.0,
            bias: CGPoint(x: 0.60, y: 0.40)
        ),
        Blob(
            colors: [
                Color(hue: 0.58, saturation: 0.70, brightness: 0.60),  // deeper blue
                Color(hue: 0.60, saturation: 0.65, brightness: 0.55),
                Color(hue: 0.62, saturation: 0.60, brightness: 0.50)
            ],
            speed: 0.008,
            xAmplitude: 0.20,
            yAmplitude: 0.26,
            phase: 3.4,
            radiusFactor: 1.2,
            bias: CGPoint(x: 0.25, y: 0.75) // lower-left-ish (darker area)
        ),
        Blob(
            colors: [
                Color(hue: 0.52, saturation: 0.55, brightness: 0.95),  // subtle light streak
                Color(hue: 0.50, saturation: 0.40, brightness: 1.00)
            ],
            speed: 0.011,
            xAmplitude: 0.28,
            yAmplitude: 0.20,
            phase: 5.1,
            radiusFactor: 0.9,
            bias: CGPoint(x: 0.85, y: 0.10) // near top-right light source
        )
    ]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            
            ZStack {
                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size)
                    let maxDimension = max(size.width, size.height)
                    
                    // Deep ocean base
                    context.fill(
                        Path(rect),
                        with: .color(
                            Color(hue: 0.60, saturation: 0.70, brightness: 0.25)
                        )
                    )
                    
                    // Global slow drift to feel like water movement
                    let globalDriftX = CGFloat(sin(t * 0.005)) * size.width * 0.03
                    let globalDriftY = CGFloat(cos(t * 0.004)) * size.height * 0.03
                    
                    for blob in blobs {
                        let localT = t * blob.speed + blob.phase
                        
                        // Gentle wave-like offsets
                        let waveX = CGFloat(cos(localT * 0.7)) * blob.xAmplitude * size.width
                        let waveY = CGFloat(sin(localT * 0.9)) * blob.yAmplitude * size.height
                        
                        let baseX = blob.bias.x * size.width
                        let baseY = blob.bias.y * size.height
                        
                        let centerX = baseX + waveX + globalDriftX
                        let centerY = baseY + waveY + globalDriftY
                        
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
                // Blur to blend blobs into a smooth mesh
                .blur(radius: 90)
                
                // Bright upper-right, darker lower-left overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),       // bright caustic light
                                Color.clear,
                                Color.black.opacity(0.45)        // darker depth
                            ],
                            startPoint: .topTrailing,  // upper-right
                            endPoint: .bottomLeading   // lower-left
                        )
                    )
                    .blendMode(.softLight)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }
}
