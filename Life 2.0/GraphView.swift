// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Graph View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.2
// Programmed Date:  November 25, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Graph view of activities (bar + pie chart only).
// ————————————————————————————————————————————————————————————————————————————————————————————————————
import SwiftUI
import SwiftData
import UIKit
import Charts
 
// Summary model for category-based pie chart
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
    @Query private var categories: [Category]
    
    // Tapped selection state
    @State private var tappedBarIcon: String? = nil
    @State private var tappedPieCategory: String? = nil
    @State private var showBarAlert: Bool = false
    @State private var showPieAlert: Bool = false
    
    init() {
        let now = Date()
        let cal = Calendar.current
        _selectedYear = State(initialValue: cal.component(.year, from: now))
        _selectedMonth = State(initialValue: cal.component(.month, from: now))
    }
    
    // MARK: - Calendar helpers
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = .current
        cal.timeZone = .current
        cal.firstWeekday = 1 // Sunday
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
        historyEntries.filter { history in
            history.dateCompleted >= monthRange.lowerBound &&
            history.dateCompleted < monthRange.upperBound
        }
    }
    
    // MARK: - Data builders
    
    // Bar chart: count per activity icon
    private func monthlyActivityCounts() -> [(icon: String, count: Int)] {
        var counts: [String: Int] = [:]
        
        for history in historiesThisMonth {
            if let icon = history.activity?.icon {
                counts[icon, default: 0] += 1
            }
        }
        
        return counts
            .map { (icon: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.icon < rhs.icon
            }
    }
    
    // Look up a color for a given SF Symbol icon from any activity that uses it
    private func colorForIcon(_ icon: String) -> Color {
        for history in historyEntries {
            if let activity = history.activity, activity.icon == icon {
                return activity.color.colorValue
            }
        }
        return .blue
    }
    
    // Pie chart: count per category with color from dominant activity in that category
    private func monthlyCategorySummaries() -> [CategorySummary] {
        var totalsByCategory: [String: Int] = [:]
        var perActivityCounts: [String: [String: Int]] = [:]
        var colorByIcon: [String: Color] = [:]
        
        for history in historiesThisMonth {
            guard let activity = history.activity else { continue }
            let category = activity.categoryName
            let icon = activity.icon
            let color = activity.color.colorValue
            
            totalsByCategory[category, default: 0] += 1
            
            var perActivity = perActivityCounts[category] ?? [:]
            perActivity[icon, default: 0] += 1
            perActivityCounts[category] = perActivity
            
            colorByIcon[icon] = color
        }
        
        var result: [CategorySummary] = []
        
        for (category, total) in totalsByCategory {
            guard let perActivity = perActivityCounts[category], !perActivity.isEmpty else {
                continue
            }
            
            // Look up the Category model to get its color
            let categoryColor: Color = categories.first(where: { $0.name == category })?.color.colorValue ?? .blue
            
            result.append(
                CategorySummary(category: category, count: total, color: categoryColor)
            )
        }
        
        return result.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.category < rhs.category
        }
    }
    
    // MARK: - Month navigation
    
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
                    
                    // MARK: Bar Chart
                    // ———————————————— BAR CHART ————————————————
                    let monthCounts = monthlyActivityCounts()
                    if !monthCounts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Count")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            Chart(monthCounts, id: \.icon) { item in
                                BarMark(
                                    x: .value("Activity", item.icon),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(colorForIcon(item.icon))
                                .annotation(position: .top) {
                                    Text("\(item.count)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.primary)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic) { value in
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
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture { location in
                                            guard let plotFrame = proxy.plotFrame else { return }
                                            let frame = geometry[plotFrame]
                                            let xInPlot = location.x - frame.origin.x
                                            if let icon: String = proxy.value(atX: xInPlot) {
                                                tappedBarIcon = icon
                                                showBarAlert = true
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // MARK: Pie Chart
                    // ———————————————— PIE CHART ————————————————
                    let categoryData = monthlyCategorySummaries()
                    if !categoryData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Count by Category")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            Chart(categoryData) { item in
                                SectorMark(
                                    angle: .value("Count", item.count)
                                )
                                // Use a discrete style key so Swift Charts can generate a legend
                                .foregroundStyle(by: .value("Category", item.category))
                                .annotation(position: .overlay) {
                                    if item.count > 0 {
                                        VStack(spacing: 2) {
                                            Text(item.category)
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                            
                                            Text("\(item.count)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                        }
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            // Map category → color (dominant activity color)
                            .chartForegroundStyleScale(
                                domain: categoryData.map { $0.category },
                                range: categoryData.map { $0.color }
                            )
                            //.chartLegend(position: .trailing)
                            .chartLegend(.hidden)
                            .frame(height: 240)
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture { location in
                                            guard let plotFrame = proxy.plotFrame else { return }
                                            let frame = geometry[plotFrame]
                                            
                                            let center = CGPoint(x: frame.midX, y: frame.midY)
                                            let dx = location.x - center.x
                                            let dy = location.y - center.y
                                            let distance = sqrt(dx * dx + dy * dy)
                                            
                                            let radius = min(frame.width, frame.height) / 2
                                            guard distance <= radius, radius > 0 else { return }
                                            
                                            var angle = atan2(dy, dx) * 180 / .pi
                                            if angle < 0 { angle += 360 }
                                            
                                            let total = categoryData.map { $0.count }.reduce(0, +)
                                            guard total > 0 else { return }
                                            
                                            var startAngle: Double = 0
                                            for slice in categoryData {
                                                let sweep = Double(slice.count) / Double(total) * 360
                                                let endAngle = startAngle + sweep
                                                
                                                if angle >= startAngle && angle < endAngle {
                                                    tappedPieCategory = slice.category
                                                    showPieAlert = true
                                                    break
                                                }
                                                
                                                startAngle = endAngle
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    if (monthCounts.isEmpty && categoryData.isEmpty) {
                        ContentUnavailableView(
                            "No Activity History",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Completed activities are needed to render graphs.")
                        )
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Overview")
            .toolbar { calendarToolbar }
            // Alerts for taps
            .alert("Activity Selected",
                   isPresented: $showBarAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You tapped activity icon: \(tappedBarIcon ?? "?")")
            }
            .alert("Category Selected",
                   isPresented: $showPieAlert) {
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
                .accessibilityLabel("Home")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: goToPreviousMonth) {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Previous Month")
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
                .accessibilityLabel("Select Month")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Picker(selection: $selectedYear) {
                    let current = Calendar.current.component(.year, from: Date())
                    let range = 2025...(current + 1)
                    ForEach(Array(range).reversed(), id: \.self) { y in
                        Text("\(y, format: .number.grouping(.never))").tag(y)
                    }
                } label: {
                    Image(systemName: "calendar")
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Select Year")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: goToNextMonth) {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel("Next Month")
            }
        }
    }
}

// MARK: - Preview

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
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
