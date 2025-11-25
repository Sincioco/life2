import SwiftUI
import Charts

struct PieSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

struct SimplePieChartView: View {
    @State private var selectedSlice: PieSlice? = nil
    @State private var showAlert = false

    private let data: [PieSlice] = [
        PieSlice(label: "A", value: 30, color: .red),
        PieSlice(label: "B", value: 40, color: .blue),
        PieSlice(label: "C", value: 20, color: .green),
        PieSlice(label: "D", value: 10, color: .orange)
    ]

    var body: some View {
        VStack {
            Text("Simple Pie Chart")
                .font(.headline)
                .padding(.top)

            Chart(data) { item in
                SectorMark(
                    angle: .value("Value", item.value)
                )
                .foregroundStyle(item.color)
                .annotation(position: .overlay) {
                    Text(item.label)
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 250)
            // 👇 Add a transparent overlay to capture taps
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    handleTap(
                                        at: value.location,
                                        chartProxy: proxy,
                                        geometry: geo
                                    )
                                }
                        )
                }
            }
        }
        .alert("Pie Slice Selected", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let slice = selectedSlice {
                Text("Label: \(slice.label)\nValue: \(slice.value)")
            } else {
                Text("No slice detected")
            }
        }
    }

    // MARK: - Tap handling

    private func handleTap(
        at location: CGPoint,
        chartProxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        // Get the plot area frame in the view’s coordinates
        let plotFrame = geometry[chartProxy.plotAreaFrame]

        // Convert tap location to coordinates relative to center of the pie
        let center = CGPoint(x: plotFrame.midX, y: plotFrame.midY)
        let dx = location.x - center.x
        let dy = location.y - center.y

        let distance = sqrt(dx * dx + dy * dy)

        // If tap is outside the pie radius, ignore
        let radius = min(plotFrame.width, plotFrame.height) / 2.0
        guard distance <= radius, radius > 0 else { return }

        // Compute angle (0..360), 0 at positive X axis, increasing counter-clockwise
        var angle = atan2(dy, dx) * 180 / .pi
        if angle < 0 { angle += 360 }

        // Find which slice this angle falls into
        let total = data.map { $0.value }.reduce(0, +)
        guard total > 0 else { return }

        var startAngle: Double = 0

        for slice in data {
            let sweep = slice.value / total * 360
            let endAngle = startAngle + sweep

            if angle >= startAngle && angle < endAngle {
                selectedSlice = slice
                showAlert = true
                return
            }

            startAngle = endAngle
        }
    }
}

#Preview {
    SimplePieChartView()
}
