import SwiftUI
import SwiftData
import UIKit

// MARK: - Activity Row with animated gauge
struct ActivityRow: View {
    @Environment(\.modelContext) private var modelContext   // ← needed to delete from SwiftData

    let activity: Activity

    @State private var animatedProgress: Double = 0
    @State private var hasAnimated = false
    @State private var showDeleteConfirm = false
    @State private var isDeletingVisual = false
    @State private var isShowingIconSheet: Bool = false
    @AppStorage("showMonthHistogram") private var showMonthHistogram: Bool = true
    @AppStorage("useRealisticIcons") private var useRealisticIcons: Bool = true
    @AppStorage("animateActivityBars") private var animateActivityBars: Bool = true   // NEW
    @AppStorage("useActivityColorForBar") private var useActivityColorForBar: Bool = true
    @AppStorage("enlargeActivityIcons") private var enlargeActivityIcons: Bool = true

    private var gaugeColor: Color {
        if useActivityColorForBar {
            return activity.color.colorValue
        } else {
            let value = activity.progress
            if value < 30 { return .red }
            else if value < 80 { return .yellow }
            else { return .green }
        }
    }


    private var isCompletedForToday: Bool {
        guard let latest = activity.histories.sorted(by: { $0.dateCompleted > $1.dateCompleted }).first else {
            return false
        }
        return Calendar.current.isDateInToday(latest.dateCompleted)
    }

    // Build a daily series for this activity for the current month (1 if any history that day)
    private func dailySeriesForCurrentMonth() -> [Int] {
        let cal = Calendar.current
        let now = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        let start = cal.startOfDay(for: startOfMonth)
        let nextMonth = cal.date(byAdding: .month, value: 1, to: start) ?? start
        let end = cal.startOfDay(for: nextMonth)

        var daysWithAny: Set<Date> = []
        for h in activity.histories where h.dateCompleted >= start && h.dateCompleted < end {
            daysWithAny.insert(cal.startOfDay(for: h.dateCompleted))
        }
        var values: [Int] = []
        var cursor = start
        while cursor < end {
            values.append(daysWithAny.contains(cursor) ? 1 : 0)
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? end
        }
        return values
    }

    // Tiny line chart for the current month (done/not-done per day) with a thin baseline
    private var monthHistogram: some View {
        let values = dailySeriesForCurrentMonth() // [0/1] per day of current month
        return GeometryReader { geo in
            let count = max(values.count, 1)
            let denom = max(count - 1, 1)
            let stepX = geo.size.width / CGFloat(denom)
            let maxY: CGFloat = 1.0
            let height = geo.size.height
            let isEmptySeries = !values.contains(1)

            ZStack(alignment: .bottomLeading) {
                // Thin baseline along the x-axis
                Rectangle()
                    .fill(.separator)
                    .frame(height: 1)

                // Smooth line path across the month
                Path { path in
                    guard !values.isEmpty else { return }

                    func point(at index: Int) -> CGPoint {
                        let x = CGFloat(index) * stepX
                        let v = min(max(CGFloat(values[index]), 0), maxY)
                        // y=0 at bottom, y=1 at top -> invert for drawing
                        let y = height - (v / maxY) * height
                        return CGPoint(x: x, y: y)
                    }

                    // Move to first point
                    path.move(to: point(at: 0))

                    if count <= 2 {
                        if count == 2 { path.addLine(to: point(at: 1)) }
                    } else {
                        // Use quadratic curves between points for a soft curve
                        for i in 1..<count {
                            let p0 = point(at: i - 1)
                            let p1 = point(at: i)
                            let mid = CGPoint(x: (p0.x + p1.x) / 2.0, y: (p0.y + p1.y) / 2.0)
                            if i == 1 {
                                path.addQuadCurve(to: mid, control: p0)
                            } else {
                                path.addQuadCurve(to: mid, control: p0)
                            }
                            if i == count - 1 {
                                path.addQuadCurve(to: p1, control: mid)
                            }
                        }
                    }
                }
                .stroke(isEmptySeries ? Color(.separator) : Color.green, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }

    var body: some View {
        HStack {
            // Activity Icon
            let icon = activity.icon
            let assetExists = UIImage(named: icon) != nil // detect if image exists in Assets
            let img: Image = {
                if useRealisticIcons, assetExists {
                    return Image(icon) // use asset image
                } else {
                    return Image(systemName: icon) // SF Symbol fallback or forced by toggle off
                }
            }()

            Button {
                isShowingIconSheet = true
            } label: {
                img
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(activity.color.colorValue)
                    .frame(width: enlargeActivityIcons ? 80 : 40) // width responds to toggle
                    .padding(0)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 15)

            // Activity Name and Progress
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    if activity.count > 0 && isCompletedForToday {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundStyle(.green)
                            .padding(.top, 2)
                    }
                    
                        Text(activity.name)
                            .font(.body)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        
                    }
                Gauge(value: animatedProgress, in: 0...100) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .gaugeStyle(.automatic)
                .tint(gaugeColor)
                .frame(maxWidth: .infinity)
                .padding(.top, -8)
                .overlay {
                    let percent = activity.maxCount > 0
                        ? Int((Double(activity.count) / Double(activity.maxCount)) * 100)
                        : 0

                    Text("\(percent)%")
                        .monospacedDigit()
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.top, -8)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("\(activity.recurrence.rawValue): \(activity.count) of \(activity.maxCount)")
                    Spacer()

                    if (activity.count > 0) {
                        HStack(spacing: 2) {
                            Text(activity.dateModified, style: .relative)
                            Text("ago")
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                // Mini histogram for the current month (done/not-done per day)
                if showMonthHistogram {
                    monthHistogram
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 10)
                        .padding(.top, 4)
                }
            }
        }
        .opacity(isDeletingVisual ? 0.0 : 1.0)
        .scaleEffect(isDeletingVisual ? 0.98 : 1.0)
        .onAppear {
            // Honor the animation toggle
            if animateActivityBars {
                // Only animate once per row
                guard !hasAnimated else { return }
                hasAnimated = true

                animatedProgress = 0
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = activity.progress
                }
            } else {
                // No animation: just snap to the real progress
                animatedProgress = activity.progress
            }
        }
        .onChange(of: animateActivityBars) { _, newValue in
            // If user flips the toggle while the row is on-screen,
            // adjust the gauge behavior accordingly.
            if newValue {
                // Re-animate from 0 to the current progress
                animatedProgress = 0
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = activity.progress
                }
            } else {
                // Snap to current progress
                withAnimation(.easeOut(duration: 0.2)) {
                    animatedProgress = activity.progress
                }
            }
        }
        // Removed swipeActions entirely as per instruction
        .alert("Delete Activity?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isDeletingVisual = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        modelContext.delete(activity)
                    }
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .activityDidChange, object: nil)
                    let error = UINotificationFeedbackGenerator()
                    error.notificationOccurred(.error)
                    isDeletingVisual = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $isShowingIconSheet) {
            VStack(spacing: 16) {
                let icon = activity.icon
                let assetExists = UIImage(named: icon) != nil
                let img: Image = {
                    if useRealisticIcons, assetExists {
                        return Image(icon)
                    } else {
                        return Image(systemName: icon)
                    }
                }()

                img
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .padding(.top, 24)

                VStack(spacing: 6) {
                    Text(activity.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Created date
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text("Created on")
                        Text(activity.dateCreated, style: .date)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Total completions (sum of histories)
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                        Text("Completed \(activity.histories.count) times total (lifetime)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                Spacer(minLength: 0)

                Button("Close", role: .cancel) {
                    isShowingIconSheet = false
                }
                .buttonStyle(.automatic)
                .padding([.horizontal, .bottom])
            }
            .presentationDetents([.medium])
        }
    }
}
