// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Graph View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.4
// Programmed Date:  November 28, 2025                                                     For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Graph view of activities (bar + pie chart + trends + streaks + AI insights).
// ————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI
import SwiftData
import UIKit
import Charts
import FoundationModels

// Summary model for category-based pie chart (THIS MONTH)
private struct CategorySummary: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let color: Color
}

// Daily total completions for trends chart (last 30 days)
private struct DailyTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// Streak information for an activity
private struct ActivityStreakSummary: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let currentStreak: Int
    let longestStreak: Int
    let color: Color
}

@Generable
private struct GraphInsights: Equatable {
    let trendsSummary: String
    let streaksSummary: String
    let encouragement: String
}

struct GraphView: View {
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @Query private var historyEntries: [ActivityHistory]
    @Query private var categories: [Category]
    
    // Tapped selection state (existing behaviour)
    @State private var tappedBarIcon: String? = nil
    @State private var tappedPieCategory: String? = nil
    @State private var showBarAlert: Bool = false
    @State private var showPieAlert: Bool = false
    
    // Derived data for new charts
    @State private var dailyTrendPoints: [DailyTrendPoint] = []
    @State private var streakSummaries: [ActivityStreakSummary] = []
    
    // Foundation Models session + insights
    @State private var lmSession = LanguageModelSession()
    @State private var insights: GraphInsights? = nil
    @State private var isGeneratingInsights: Bool = false
    @State private var insightsError: String? = nil
    
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
    
    // MARK: - Data builders (existing)
    
    // Bar chart: count per activity icon (TOP 10 only) – THIS MONTH
    private func monthlyActivityCounts() -> [(icon: String, count: Int)] {
        var counts: [String: Int] = [:]
        
        for history in historiesThisMonth {
            if let icon = history.activity?.icon {
                counts[icon, default: 0] += 1
            }
        }
        
        let sorted = counts
            .map { (icon: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.icon < rhs.icon
            }
        
        // Only keep the top 10
        return Array(sorted.prefix(10))
    }
    
    // Look up a color for a given SF Symbol / icon from any activity that uses it
    private func colorForIcon(_ icon: String) -> Color {
        for history in historyEntries {
            if let activity = history.activity, activity.icon == icon {
                return activity.color.colorValue
            }
        }
        return .blue
    }
    
    // Pie chart: count per category, but ONLY from the top 10 activities for the month
    private func monthlyCategorySummaries() -> [CategorySummary] {
        // Get the same top-10 activities used by the bar chart
        let topActivities = monthlyActivityCounts()
        let topIcons = Set(topActivities.map { $0.icon })
        
        guard !topIcons.isEmpty else { return [] }
        
        var totalsByCategory: [String: Int] = [:]
        
        // Only count histories whose activity.icon is in the top-10 set
        for history in historiesThisMonth {
            guard let activity = history.activity else { continue }
            guard topIcons.contains(activity.icon) else { continue }
            
            let categoryName = activity.categoryName
            totalsByCategory[categoryName, default: 0] += 1
        }
        
        var result: [CategorySummary] = []
        
        for (categoryName, total) in totalsByCategory {
            // Use Category model color for the slice
            let categoryColor: Color =
                categories.first(where: { $0.name == categoryName })?.color.colorValue ?? .blue
            
            result.append(
                CategorySummary(category: categoryName, count: total, color: categoryColor)
            )
        }
        
        return result.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.category < rhs.category
        }
    }
    
    // MARK: - NEW: Trends + Streaks data
    
    /// Build daily total completions for the last `days` days (including today)
    private func buildDailyTrendPoints(days: Int = 30) -> [DailyTrendPoint] {
        guard !historyEntries.isEmpty else { return [] }
        
        let now = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: now) else {
            return []
        }
        
        var countsByDay: [Date: Int] = [:]
        
        for entry in historyEntries {
            let day = calendar.startOfDay(for: entry.dateCompleted)
            guard day >= start && day <= now else { continue }
            countsByDay[day, default: 0] += 1
        }
        
        var result: [DailyTrendPoint] = []
        var cursor = start
        while cursor <= now {
            let count = countsByDay[cursor, default: 0]
            result.append(DailyTrendPoint(date: cursor, count: count))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        
        return result
    }
    
    /// Compute current + longest streaks per activity based on unique completion days.
    private func buildStreakSummaries(limit: Int = 5) -> [ActivityStreakSummary] {
        // Group histories by a stable activity key (avoid requiring Activity: Hashable)
        // Use a compound key of name + icon to distinguish activities.
        var historiesByActivityKey: [String: [ActivityHistory]] = [:]
        var activityInfoByKey: [String: (name: String, icon: String, color: Color)] = [:]
        for entry in historyEntries {
            guard let activity = entry.activity else { continue }
            let key = "\(activity.name)|\(activity.icon)"
            historiesByActivityKey[key, default: []].append(entry)
            // Capture display info from the first seen entry for this key
            if activityInfoByKey[key] == nil {
                activityInfoByKey[key] = (name: activity.name, icon: activity.icon, color: activity.color.colorValue)
            }
        }
        
        func streaks(from entries: [ActivityHistory]) -> (current: Int, longest: Int) {
            // Unique completion days
            let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.dateCompleted) })
            let sorted = uniqueDays.sorted()
            guard !sorted.isEmpty else { return (0, 0) }
            
            // Longest streak
            var longest = 0
            var runLength = 0
            var previousDay: Date? = nil
            
            for day in sorted {
                if let prev = previousDay,
                   let expectedNext = calendar.date(byAdding: .day, value: 1, to: prev),
                   calendar.isDate(expectedNext, inSameDayAs: day) {
                    runLength += 1
                } else {
                    runLength = 1
                }
                longest = max(longest, runLength)
                previousDay = day
            }
            
            // Current streak: count backwards from the most recent day while days are consecutive
            var current = 0
            var index = sorted.count - 1
            var expected = sorted[index]
            
            while true {
                let day = sorted[index]
                if !calendar.isDate(day, inSameDayAs: expected) {
                    break
                }
                current += 1
                if index == 0 { break }
                index -= 1
                guard let prevExpected = calendar.date(byAdding: .day, value: -1, to: expected) else { break }
                expected = prevExpected
            }
            
            return (current, longest)
        }
        
        var summaries: [ActivityStreakSummary] = []
        
        for (key, entries) in historiesByActivityKey {
            let (current, longest) = streaks(from: entries)
            // Ignore trivial streaks
            guard current > 0 || longest > 1 else { continue }
            
            if let info = activityInfoByKey[key] {
                summaries.append(
                    ActivityStreakSummary(
                        name: info.name,
                        icon: info.icon,
                        currentStreak: current,
                        longestStreak: longest,
                        color: info.color
                    )
                )
            }
        }
        
        let sorted = summaries.sorted { lhs, rhs in
            if lhs.currentStreak != rhs.currentStreak {
                return lhs.currentStreak > rhs.currentStreak
            }
            if lhs.longestStreak != rhs.longestStreak {
                return lhs.longestStreak > rhs.longestStreak
            }
            return lhs.name < rhs.name
        }
        
        return Array(sorted.prefix(limit))
    }
    
    private func rebuildDerivedData() {
        dailyTrendPoints = buildDailyTrendPoints()
        streakSummaries = buildStreakSummaries()
    }
    
    // MARK: - NEW: Foundation Models – insights
    
    /// Build a compact JSON-like snapshot of the user's recent activity to feed into the LLM.
    private func buildInsightsSnapshot() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = calendar.locale
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let monthCounts = monthlyActivityCounts()
        
        let totalThisMonth = historiesThisMonth.count
        let totalLast30Days = dailyTrendPoints.reduce(0) { $0 + $1.count }
        
        let daily = dailyTrendPoints.map { point in
            """
            { "date": "\(dateFormatter.string(from: point.date))", "count": \(point.count) }
            """
        }.joined(separator: ", ")
        
        let streaks = streakSummaries.map { s in
            """
            { "name": "\(s.name)", "currentStreak": \(s.currentStreak), "longestStreak": \(s.longestStreak) }
            """
        }.joined(separator: ", ")
        
        let topActivities = monthCounts.map { item in
            """
            { "icon": "\(item.icon)", "count": \(item.count) }
            """
        }.joined(separator: ", ")
        
        return """
        {
          "selectedMonth": \(selectedMonth),
          "selectedYear": \(selectedYear),
          "totalThisMonth": \(totalThisMonth),
          "totalLast30Days": \(totalLast30Days),
          "dailyCountsLast30Days": [\(daily)],
          "streaks": [\(streaks)],
          "topActivitiesThisMonth": [\(topActivities)]
        }
        """
    }
    
    @MainActor
    private func generateInsightsIfNeeded() async {
        guard !historyEntries.isEmpty else {
            insights = nil
            insightsError = nil
            return
        }
        guard !isGeneratingInsights else { return }
        
        isGeneratingInsights = true
        insightsError = nil
        
        let snapshot = buildInsightsSnapshot()
        
        do {
            let options = GenerationOptions(
                sampling: .greedy,
                temperature: 0.4,
                maximumResponseTokens: 220
            )
            
            let response = try await lmSession.respond(
                to: """
                You are a friendly, encouraging personal coach inside an app called \"Life 2.0\".
                The app tracks when the user completes activities as individual history entries.

                I will give you a compact JSON snapshot describing:
                - How many activities were completed this month.
                - A 30-day history of daily completion counts.
                - The user's best activity streaks.
                - The top activities for the currently selected month.

                Based on this snapshot:
                1. Write a short trends summary (1–2 sentences) that comments on overall momentum.
                2. Write a short activity streaks summary (1–2 sentences) that highlights consistency.
                3. Write a short encouragement message (1–3 sentences) that is specific, supportive, and optimistic.

                Keep everything positive, concrete, and concise.
                Do NOT invent data; base your wording on the numbers.

                Snapshot:
                \(snapshot)
                """,
                generating: GraphInsights.self,
                includeSchemaInPrompt: true,
                options: options
            )
            
            insights = response.content
            isGeneratingInsights = false
        } catch {
            insightsError = error.localizedDescription
            isGeneratingInsights = false
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
                            Text("Top 10 Activities")
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
                            Text("Top 10 Activities by Category")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            Chart(categoryData) { item in
                                SectorMark(
                                    angle: .value("Count", item.count)
                                )
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
                            .chartForegroundStyleScale(
                                domain: categoryData.map { $0.category },
                                range: categoryData.map { $0.color }
                            )
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
                    
                    // MARK: Trends Analysis (NEW)
                    // ———————————————— TRENDS ————————————————
                    if !dailyTrendPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trends (Last 30 Days)")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            Chart(dailyTrendPoints) { point in
                                LineMark(
                                    x: .value("Day", point.date),
                                    y: .value("Completions", point.count)
                                )
                                AreaMark(
                                    x: .value("Day", point.date),
                                    y: .value("Completions", point.count)
                                )
                                .opacity(0.2)
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic) { value in
                                    if let date = value.as(Date.self) {
                                        AxisValueLabel {
                                            Text(date, format: .dateTime.day().month(.abbreviated))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 220)
                        }
                        .padding()
                    }
                    
                    // MARK: Activity Streaks (NEW)
                    // ———————————————— STREAKS ————————————————
                    if !streakSummaries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Streaks")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            Chart(streakSummaries) { item in
                                BarMark(
                                    x: .value("Current Streak", item.currentStreak),
                                    y: .value("Activity", item.name)
                                )
                                .foregroundStyle(item.color)
                                .annotation(position: .trailing, alignment: .center) {
                                    Text("\(item.currentStreak)d")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: max(160, CGFloat(streakSummaries.count) * 28))
                        }
                        .padding()
                    }
                    
                    // MARK: AI Insights (NEW – Foundation Models)
                    // ———————————————— AI INSIGHTS ————————————————
                    aiInsightsSection
                    
                    if monthCounts.isEmpty &&
                        categoryData.isEmpty &&
                        dailyTrendPoints.isEmpty &&
                        streakSummaries.isEmpty {
                        ContentUnavailableView(
                            "No Activity History",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Completed activities are needed to render graphs and insights.")
                        )
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Overview")
            .toolbar { calendarToolbar }
            .task(id: taskID) {
                rebuildDerivedData()
                await generateInsightsIfNeeded()
            }
            .onChange(of: historyEntries.count) { _, _ in
                rebuildDerivedData()
                Task {
                    await generateInsightsIfNeeded()
                }
            }
        }
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
    
    // Simple id that changes when the visible month or history changes
    private var taskID: String {
        "\(selectedYear)-\(selectedMonth)-\(historyEntries.count)"
    }
    
    // MARK: - AI Insights section
    
    @ViewBuilder
    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("AI Insights")
                    .font(.headline)
            }
            
            if isGeneratingInsights {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Analyzing your progress…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let insights {
                VStack(alignment: .leading, spacing: 6) {
                    Text(insights.trendsSummary)
                        .font(.subheadline)
                    Text(insights.streaksSummary)
                        .font(.subheadline)
                    Divider()
                        .padding(.vertical, 4)
                    Text(insights.encouragement)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            } else if let error = insightsError {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unable to generate insights right now.")
                        .font(.subheadline)
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Complete a few activities to unlock personalized trends, streaks, and encouragement.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Spacer()
                Button {
                    Task {
                        await generateInsightsIfNeeded()
                    }
                } label: {
                    Label("Refresh Insights", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
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
                .accessibilityLabel("Current Month")
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

