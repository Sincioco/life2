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
    
    @State private var selectedActivityCount: String?
    @State private var selectedCategoryRawCount: Int?
    @State private var selectedCategoryName: String?

    
    init() {
        let now = Date()
        let cal = Calendar.current
        _selectedYear = State(initialValue: cal.component(.year, from: now))
        _selectedMonth = State(initialValue: cal.component(.month, from: now))
    }

    // Calendar for date calculations
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = .current
        cal.timeZone = .current
        cal.firstWeekday = 1 // Sunday
        return cal
    }

    // Start of selected month
    private var monthStart: Date {
        calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) ?? Date()
    }

    // Range of the selected month [start, start of next month)
    private var monthRange: Range<Date> {
        let start = calendar.startOfDay(for: monthStart)
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        return start..<nextMonth
    }

    // Filtered histories in the selected month
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

        // Map dictionary entries into the labeled tuple type and sort by count, then icon
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
            let category = activity.category
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

            // Icon with the highest count for this category in the selected month
            let dominant = perActivity.max { a, b in a.value < b.value }
            let dominantIcon = dominant?.key ?? perActivity.first!.key
            let color = colorByIcon[dominantIcon] ?? .blue

            result.append(
                CategorySummary(category: category, count: total, color: color)
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

                            Chart(monthCounts, id: \.icon) { item in
                                BarMark(
                                    x: .value("Activity", item.icon),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(colorForIcon(item.icon))
                                // ✅ Always show the label, clearly visible, above the bar
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
                            
                            .chartXSelection(value: $selectedActivityCount)
                            .onChange(of: selectedActivityCount) { oldValue, newValue in
                                print(newValue ?? "No Value")
                            }
                            .frame(height: 200)
                        }
                        .padding()
                    }

                    // MARK: Pie Chart
                    // ———————————————— PIE CHART ————————————————
                    let categoryData = monthlyCategorySummaries()
                    if !categoryData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity by Category")
                                .font(.headline)

                            Chart(categoryData) { item in
                                SectorMark(
                                    angle: .value("Count", item.count)
                                )
                                .foregroundStyle(by: .value("Category", item.category))
                            }
                            .chartForegroundStyleScale(
                                domain: categoryData.map { $0.category },
                                range: categoryData.map { $0.color }
                            )
                            
                            .chartAngleSelection(value: $selectedCategoryRawCount)
                            .onChange(of: selectedCategoryRawCount) { oldValue, newValue in
                                guard let newValue else {
                                    selectedCategoryName = nil
                                    return
                                }
                                // Map raw count back to a category based on cumulative totals
                                var running = 0
                                for item in categoryData {
                                    running += item.count
                                    if newValue <= running {
                                        selectedCategoryName = item.category
                                        break
                                    }
                                }
                                print("Selected category: \(selectedCategoryName ?? "?") (raw: \(newValue))")
                            }
                            .chartLegend(position: .trailing)
                            .frame(height: 240)
                        }
                        .padding()
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Overview")
            .toolbar { calendarToolbar }
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
