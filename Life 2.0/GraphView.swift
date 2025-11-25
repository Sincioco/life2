// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Graph View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.1
// Programmed Date:  November 25, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Graph view of activities (bar + pie chart only).
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI
import SwiftData
import UIKit
import Charts

private struct CategorySummary: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let color: Color
}

struct GraphView: View {

    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @Query private var historyEntries: [ActivityHistory]

    // Tapped selection
    @State private var tappedBarIcon: String? = nil
    @State private var tappedPieCategory: String? = nil
    @State private var showBarAlert = false
    @State private var showPieAlert = false

    init() {
        let now = Date()
        let cal = Calendar.current
        _selectedYear = State(initialValue: cal.component(.year, from: now))
        _selectedMonth = State(initialValue: cal.component(.month, from: now))
    }

    // MARK: Calendar helpers

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = .current
        cal.timeZone = .current
        cal.firstWeekday = 1
        return cal
    }

    private var monthStart: Date {
        calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) ?? Date()
    }

    private var monthRange: Range<Date> {
        let start = calendar.startOfDay(for: monthStart)
        let next = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return start..<next
    }

    private var historiesThisMonth: [ActivityHistory] {
        historyEntries.filter {
            $0.dateCompleted >= monthRange.lowerBound &&
            $0.dateCompleted < monthRange.upperBound
        }
    }

    // MARK: Data Builders

    private func monthlyActivityCounts() -> [(icon: String, count: Int)] {
        var dict: [String: Int] = [:]
        for h in historiesThisMonth {
            if let icon = h.activity?.icon {
                dict[icon, default: 0] += 1
            }
        }
        return dict.map { ($0.key, $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.icon < rhs.icon
            }
    }

    private func colorForIcon(_ icon: String) -> Color {
        for h in historyEntries {
            if let a = h.activity, a.icon == icon {
                return a.color.colorValue
            }
        }
        return .blue
    }

    private func monthlyCategorySummaries() -> [CategorySummary] {
        var totals: [String: Int] = [:]
        var perActivity: [String: [String: Int]] = [:]
        var iconColor: [String: Color] = [:]

        for h in historiesThisMonth {
            guard let a = h.activity else { continue }
            let cat = a.category
            totals[cat, default: 0] += 1

            var inner = perActivity[cat] ?? [:]
            inner[a.icon, default: 0] += 1
            perActivity[cat] = inner

            iconColor[a.icon] = a.color.colorValue
        }

        var output: [CategorySummary] = []

        for (category, total) in totals {
            guard let inner = perActivity[category], !inner.isEmpty else { continue }
            let dominant = inner.max { $0.value < $1.value }
            let domIcon = dominant?.key ?? inner.first!.key
            output.append(CategorySummary(
                category: category,
                count: total,
                color: iconColor[domIcon] ?? .blue
            ))
        }

        return output.sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.category < $1.category
        }
    }

    // MARK: - Month Navigation

    private func goToPreviousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func goToNextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - View

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ——————————————— BAR CHART ———————————————

                    let barData = monthlyActivityCounts()
                    if !barData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Count")
                                .font(.headline)

                            Chart(barData, id: \.icon) { item in
                                BarMark(
                                    x: .value("Activity", item.icon),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(colorForIcon(item.icon))
                                .annotation(position: .top) {
                                    Text("\(item.count)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    if let icon = value.as(String.self) {
                                        AxisValueLabel {
                                            Image(systemName: icon)
                                                .font(.caption)
                                                .foregroundStyle(colorForIcon(icon))
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)

                            // TAP overlay for bar chart
                            .chartOverlay { proxy in
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture { point in
                                            // ⬇️ Safely unwrap plotFrame (Anchor<CGRect>?)
                                            guard let plotFrame = proxy.plotFrame else { return }
                                            let frame = geo[plotFrame]
                                            let x = point.x - frame.origin.x

                                            if let tapped: String = proxy.value(atX: x) {
                                                tappedBarIcon = tapped
                                                showBarAlert = true
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                    }

                    // ——————————————— PIE CHART ———————————————

                    let pieData = monthlyCategorySummaries()
                    if !pieData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity by Category")
                                .font(.headline)

                            Chart(pieData) { item in
                                SectorMark(
                                    angle: .value("Count", item.count)
                                )
                                .foregroundStyle(item.color)
                            }
                            .chartLegend(position: .trailing)
                            .frame(height: 240)

                            // TAP overlay for pie chart
                            .chartOverlay { proxy in
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture { tap in
                                            // ⬇️ Safely unwrap plotFrame here too
                                            guard let plotFrame = proxy.plotFrame else { return }
                                            let frame = geo[plotFrame]
                                            let center = CGPoint(x: frame.midX, y: frame.midY)

                                            let dx = tap.x - center.x
                                            let dy = tap.y - center.y
                                            let dist = sqrt(dx * dx + dy * dy)

                                            let radius = min(frame.width, frame.height) / 2
                                            guard dist <= radius else { return }

                                            var angle = atan2(dy, dx) * 180 / .pi
                                            if angle < 0 { angle += 360 }

                                            // Find slice
                                            let total = pieData.reduce(0) { $0 + $1.count }
                                            guard total > 0 else { return }

                                            var start: Double = 0
                                            for item in pieData {
                                                let sweep = Double(item.count) / Double(total) * 360
                                                let end = start + sweep

                                                if angle >= start && angle < end {
                                                    tappedPieCategory = item.category
                                                    showPieAlert = true
                                                    break
                                                }
                                                start = end
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Overview")
            .toolbar { calendarToolbar }

            // Alerts
            .alert("Bar Tapped", isPresented: $showBarAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You tapped on activity icon: \(tappedBarIcon ?? "?")")
            }
            .alert("Pie Slice Tapped", isPresented: $showPieAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You tapped category: \(tappedPieCategory ?? "?")")
            }
        }
    }

    // MARK: - Toolbar

    private var calendarToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    let now = Date()
                    selectedYear = calendar.component(.year, from: now)
                    selectedMonth = calendar.component(.month, from: now)
                } label: {
                    Image(systemName: "house")
                }
            }

            ToolbarItem(placement: .automatic) {
                Button(action: goToPreviousMonth) {
                    Image(systemName: "chevron.left")
                }
            }

            ToolbarItem(placement: .automatic) {
                Picker(selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { m in
                        Text(DateFormatter().monthSymbols[m - 1]).tag(m)
                    }
                } label: {
                    Image(systemName: "calendar.badge.plus")
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            ToolbarItem(placement: .topBarTrailing) {
                Picker(selection: $selectedYear) {
                    let current = Calendar.current.component(.year, from: Date())
                    let range = 2025...(current + 1)
                    ForEach(Array(range).reversed(), id: \.self) { y in
                        Text("\(y)").tag(y)
                    }
                } label: {
                    Image(systemName: "calendar")
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: goToNextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Activity.self,
            ActivityHistory.self,
            configurations: config
        )
        return GraphView()
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error)")
    }
}
