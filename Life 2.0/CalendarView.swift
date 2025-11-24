// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Calendar View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 21, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Calendar view of activities.
// ————————————————————————————————————————————————————————————————————————————————————————————————————
import SwiftUI
import SwiftData
import UIKit
import Charts

struct CalendarView: View {
    let year: Int
    let month: Int // 1...12
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var sheetDate: IdentifiableDate? = nil
    @Query private var historyEntries: [ActivityHistory]
//    @State private var calendarGridHeight: CGFloat = 0
//    @State private var isShowingHeightAlert = false
    
    private enum CalendarTab: String, CaseIterable, Identifiable {
        case calendar = "Calendar"
        case chart = "Chart"
        var id: String { rawValue }
    }
    
    @State private var selectedTab: CalendarTab = .calendar
    
    init(year: Int? = nil, month: Int? = nil) {
        let now = Date()
        let cal = Calendar(identifier: .gregorian)
        let resolvedYear = year ?? cal.component(.year, from: now)
        let resolvedMonth = month ?? cal.component(.month, from: now)
        self.year = resolvedYear
        self.month = resolvedMonth
        _selectedYear = State(initialValue: resolvedYear)
        _selectedMonth = State(initialValue: resolvedMonth)
    }
    
    // Deterministic Gregorian calendar (Sunday-first), stable across locales/time zones
    private var calendar: Calendar {
        var cal = Calendar.current
        // Ensure we operate in the user's local time and locale
        cal.timeZone = TimeZone.current
        cal.locale = Locale.current
        cal.firstWeekday = 1 // Sunday
        return cal
    }
    
    private var monthStart: Date {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = 1
        return calendar.date(from: comps) ?? Date()
    }
    
    private var previousMonthStart: Date {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth - 1
        comps.day = 1
        return calendar.date(from: comps) ?? Date()
    }
    
    private var nextMonthStart: Date {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth + 1
        comps.day = 1
        return calendar.date(from: comps) ?? Date()
    }
    
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
    
    private var daysInPreviousMonthCount: Int {
        let range = calendar.range(of: .day, in: .month, for: previousMonthStart) ?? 1..<29
        return range.count
    }
    
    private var daysInCurrentMonth: [Int] {
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<29
        return Array(range)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "LLLL yyyy" // full month name
        return formatter.string(from: monthStart)
    }
    
    private var weekdaySymbols: [String] { calendar.shortWeekdaySymbols } // Sun..Sat
    
    private var monthDateRange: Range<Date> {
        // Local start of day for the first day of the selected month
        let start = calendar.startOfDay(for: monthStart)
        // Compute the first moment of the next month in local time
        let nextMonth = calendar.date(byAdding: DateComponents(month: 1), to: monthStart) ?? monthStart
        let end = calendar.startOfDay(for: nextMonth)
        return start..<end
    }
    
    private var historyThisMonth: [ActivityHistory] {
        historyEntries.filter { entry in
            entry.dateCompleted >= monthDateRange.lowerBound && entry.dateCompleted < monthDateRange.upperBound
        }
    }
    private func historyEntries(on date: Date) -> [ActivityHistory] {
        historyEntries
            .filter { entry in
                calendar.isDate(entry.dateCompleted, inSameDayAs: date)
            }
            .sorted { $0.dateCompleted > $1.dateCompleted }
    }
    
    
    
    private func iconsFor(date: Date) -> [String] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let todays = historyThisMonth.filter { entry in
            entry.dateCompleted >= startOfDay && entry.dateCompleted < endOfDay
        }
        // Map to activity icons and remove duplicates so each activity's icon appears only once per day
        let icons = todays.compactMap { $0.activity?.icon }
        var seen = Set<String>()
        var uniqueIcons: [String] = []
        for icon in icons where !seen.contains(icon) {
            seen.insert(icon)
            uniqueIcons.append(icon)
        }
        return uniqueIcons
    }
    
    private func uniqueIcons(date: Date) -> [String] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        // Filter directly from all history entries for this exact local day
        let todays = historyEntries.filter { entry in
            entry.dateCompleted >= startOfDay && entry.dateCompleted < endOfDay
        }
        
        // Map to icons and de-duplicate while preserving first-seen order
        var seen = Set<String>()
        var unique: [String] = []
        for icon in todays.compactMap({ $0.activity?.icon }) where !seen.contains(icon) {
            seen.insert(icon)
            unique.append(icon)
        }
        return unique
    }
    
    private func monthlyActivityCounts() -> [(icon: String, count: Int)] {
        // Count entries per activity icon within the currently selected month
        var counts: [String: Int] = [:]
        for entry in historyThisMonth {
            if let icon = entry.activity?.icon {
                counts[icon, default: 0] += 1
            }
        }
        // Sort by count descending, then icon name
        return counts
            .map { ($0.key, $0.value) }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0 < rhs.0
            }
    }
    
    private func dateForCurrentMonth(day: Int) -> Date {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = day
        return calendar.date(from: comps) ?? monthStart
    }
    
    // Build a flat array of 7 header cells + leading prev month days + current days + trailing next month days
    private var cells: [Cell] {
        var items: [Cell] = []
        // Headers (Sun..Sat)
        for i in 0..<7 { items.append(.header(weekdaySymbols[i])) }
        
        // Leading relative to Sunday column 0
        let firstWeekday = calendar.component(.weekday, from: monthStart) // 1..7 (Sun=1)
        let leading = (firstWeekday - 1 + 7) % 7
        if leading > 0 {
            let start = daysInPreviousMonthCount - leading + 1
            for d in start...daysInPreviousMonthCount {
                items.append(.adjacent(d, true)) // previous month days
            }
        }
        
        // Current month days
        for d in daysInCurrentMonth { items.append(.day(d)) }
        
        // Trailing to fill the last week
        let totalDayCells = leading + daysInCurrentMonth.count
        let trailing = (7 - (totalDayCells % 7)) % 7
        if trailing > 0 {
            for d in 1...trailing { items.append(.adjacent(d, false)) } // next month days
        }
        return items
    }
    
    private func columns(for totalWidth: CGFloat) -> [GridItem] {
        let cellWidth = totalWidth / 7.0
        
        return Array(
            repeating: GridItem(.fixed(cellWidth), spacing: 0),
            count: 7
        )
    }
    
    private var gridHeight: CGFloat { 40 + 100 * 6 + 16 } // header + 6 rows + vertical padding
    
    enum Cell: Hashable {
        case header(String)
        case adjacent(Int, Bool) // (day, isPrevious)
        case day(Int)
    }
    
    
    
    private func iconsGrid(for icons: [String], isLandscape: Bool) -> some View {
        // Render all icons under the day label.
        // For up to 6 icons we center them vertically & horizontally without scrolling.
        // For more than 6 icons, we fall back to a scrollable grid.
        
        let allIcons = icons
        let iconCount = allIcons.count
        
        // Base icon size for the grid
        let baseSize: CGFloat
        switch iconCount {
        case 0:
            baseSize = 0
        case 1:
            baseSize = 26
        case 2...4:
            baseSize = 22
        case 5 where isLandscape:
            // Make 5 icons a bit larger in landscape
            baseSize = 24
        default:
            baseSize = 16
        }
        
        // Break into rows of up to 3 icons (3-per-row grid)
        let rows: [[String]] = stride(from: 0, to: allIcons.count, by: 3).map { index in
            Array(allIcons[index..<min(index + 3, allIcons.count)])
        }
        
        let hSpacing: CGFloat = 2
        let vSpacing: CGFloat = 2
        
        return Group {
            if iconCount <= 6 {
                // No scrolling needed: center grid vertically & horizontally in the available space.
                ZStack {
                    // Debug background to visualize the icon area bounds
                    Color.yellow.opacity(0.3)
                    
                    VStack {
                        Spacer(minLength: 0)
                        
                        VStack(alignment: .center, spacing: vSpacing) {
                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                HStack(spacing: hSpacing) {
                                    Spacer(minLength: 0)
                                    ForEach(row, id: \.self) { iconName in
                                        Image(systemName: iconName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: baseSize, height: baseSize)
                                            .foregroundStyle(.green)
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
                
            } else {
                // 7+ icons: scrollable grid, using the original layout.
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            HStack(spacing: 2) {
                                ForEach(row, id: \.self) { iconName in
                                    Image(systemName: iconName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: baseSize, height: baseSize)
                                        .foregroundStyle(.green)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
                .background(Color.yellow.opacity(0.3))
            }
        }
    }
    
    // MARK:  Calendar View
    var body: some View {
        
        
        
        NavigationStack {
            Group {
                GeometryReader { proxy in
                    let totalWidth = proxy.size.width
                    let isLandscape = proxy.size.width > proxy.size.height
                    let dayCellWidth = totalWidth / 7.0
                    let dayCellHeight = dayCellWidth
                    
//                    ScrollView(.vertical) {
//                        VStack(spacing: 12) {
//                            Picker("View Mode", selection: $selectedTab) {
//                                ForEach(CalendarTab.allCases) { tab in
//                                    Text(tab.rawValue).tag(tab)
//                                }
//                            }
//                            .pickerStyle(.segmented)
//                            .padding(.horizontal)
//                            .accessibilityLabel("View Mode")
//                            .padding()
//                            
//                            switch selectedTab {
//                            case .calendar:
//                                VStack(spacing: 0) {
//                                    CalendarMonthGrid(
//                                        cells: cells,
//                                        dayCellHeight: dayCellHeight,
//                                        isLandscape: isLandscape,
//                                        calendar: calendar,
//                                        selectedYear: selectedYear,
//                                        selectedMonth: selectedMonth,
//                                        dateForCurrentMonth: dateForCurrentMonth,
//                                        iconsFor: iconsFor,
//                                        uniqueIcons: uniqueIcons,
//                                        onSelectDay: { date in
//                                            sheetDate = IdentifiableDate(date: date)
//                                        }
//                                    )
//                                    //.frame(height: 450)
//                                    .padding()
//                                    .background(
//                                        GeometryReader { gridProxy in
//                                            Color.clear
//                                                .onAppear {
//                                                    calendarGridHeight = gridProxy.size.height
//                                                }
//                                                .onChange(of: gridProxy.size.height) { newHeight in
//                                                    calendarGridHeight = newHeight
//                                                }
//                                        }
//                                    )
//                                    
//                                    MonthlySummaryChart(monthActivities: monthlyActivityCounts())
//                                    
//                                    Button("Test") {
//                                        isShowingHeightAlert = true
//                                    }
//                                    
//                                }
//                                .frame(maxWidth: .infinity)
//                                
//                            case .chart:
//                                //                                VStack(spacing: 16) {
//                                MonthlySummaryChart(monthActivities: monthlyActivityCounts())
//                                    .padding(.horizontal)
//                                //                                }
//                                //                                .frame(maxWidth: .infinity)
//                            }
//                        }
//                    }
                    
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            CalendarMonthGrid(
                                cells: cells,
                                dayCellHeight: dayCellHeight,
                                isLandscape: isLandscape,
                                calendar: calendar,
                                selectedYear: selectedYear,
                                selectedMonth: selectedMonth,
                                dateForCurrentMonth: dateForCurrentMonth,
                                iconsFor: iconsFor,
                                uniqueIcons: uniqueIcons,
                                onSelectDay: { date in
                                    sheetDate = IdentifiableDate(date: date)
                                }
                            )
                            //.frame(height: 450)
                            .padding()
//                            .background(
//                                GeometryReader { gridProxy in
//                                    Color.clear
//                                        .onAppear {
//                                            calendarGridHeight = gridProxy.size.height
//                                        }
//                                        .onChange(of: gridProxy.size.height) { newHeight in
//                                            calendarGridHeight = newHeight
//                                        }
//                                }
//                            )
                            
                            MonthlySummaryChart(monthActivities: monthlyActivityCounts())
                                //.padding(.horizontal)
                                .padding()
                            
//                            Button("Test") {
//                                isShowingHeightAlert = true
//                            }
                            
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            //.navigationTitle(monthName)
            .sheet(item: $sheetDate) { identifiable in
                let date = identifiable.date
                DayActivitySheet(
                    date: date,
                    entries: historyEntries(on: date),
                    calendar: calendar
                )
            }
            .toolbar { calendarToolbar }
        }
        .sheet(item: $sheetDate) { identifiable in
            let date = identifiable.date
            DayActivitySheet(
                date: date,
                entries: historyEntries(on: date),
                calendar: calendar
            )
        }
//        .alert("Calendar Grid Height", isPresented: $isShowingHeightAlert) {
//            Button("OK", role: .cancel) { }
//        } message: {
//            Text("Height: \(Int(calendarGridHeight))")
//        }
    }
    
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

private struct CalendarMonthGrid: View {
    let cells: [CalendarView.Cell]
    let dayCellHeight: CGFloat
    let isLandscape: Bool
    let calendar: Calendar
    let selectedYear: Int
    let selectedMonth: Int
    let dateForCurrentMonth: (Int) -> Date
    let iconsFor: (Date) -> [String]
    let uniqueIcons: (Date) -> [String]
    let onSelectDay: (Date) -> Void
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(cells, id: \.self) { cell in
                switch cell {
                case .header(let title):
                    HeaderCell(title: title)
                        .frame(height: 40)
                case .adjacent(let d, _):
                    AdjacentDayCell(
                        day: d,
                        isLandscape: isLandscape,
                        calendar: calendar,
                        selectedYear: selectedYear,
                        selectedMonth: selectedMonth,
                        uniqueIcons: uniqueIcons
                    )
                    .frame(height: dayCellHeight)
                case .day(let d):
                    let date = dateForCurrentMonth(d)
                    let icons = iconsFor(date)
                    DayCellView(date: date, isLandscape: isLandscape, icons: icons) {
                        onSelectDay(date)
                    }
                    .frame(height: dayCellHeight)
                }
            }
        }
    }
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: 7)
    }
}

private struct HeaderCell: View {
    let title: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.secondarySystemBackground))
            Text(title)
                .font(.headline)
        }
    }
}

private struct DayCellView: View {
    let date: Date
    let isLandscape: Bool
    let icons: [String]
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.3))
                )
            Group {
                if isLandscape {
                    CalendarDayCell(day: date, cellWidth: 119, cellHeight: 119, icons: icons, adjacentCell: false, cellDebug: false)
                } else {
                    CalendarDayCell(day: date, cellWidth: 63, cellHeight: 63, icons: icons, adjacentCell: false, cellDebug: false)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

private struct AdjacentDayCell: View {
    let day: Int
    let isLandscape: Bool
    let calendar: Calendar
    let selectedYear: Int
    let selectedMonth: Int
    let uniqueIcons: (Date) -> [String]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.25))
                )
            content
        }
    }
    
    private var content: some View {
        let date1 = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1))!
        let previousMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: date1)!
        let nextMonthDate = Calendar.current.date(byAdding: .month, value: 1, to: date1)!
        
        let prevComps = Calendar.current.dateComponents([.year, .month], from: previousMonthDate)
        let nextComps = Calendar.current.dateComponents([.year, .month], from: nextMonthDate)
        
        let prevYear = prevComps.year!
        let prevMonth = prevComps.month!
        let nextYear = nextComps.year!
        let nextMonth = nextComps.month!
        
        // Determine if this adjacent day belongs to previous or next month based on day number
        let isPrev = (day >= 26 && day <= 31)
        let targetDate: Date = {
            if isPrev {
                return Calendar.current.date(from: DateComponents(year: prevYear, month: prevMonth, day: day))!
            } else {
                return Calendar.current.date(from: DateComponents(year: nextYear, month: nextMonth, day: day))!
            }
        }()
        
        let icons = uniqueIcons(targetDate)
        
        return Group {
            if isLandscape {
                CalendarDayCell(day: targetDate, cellWidth: 119, cellHeight: 119, icons: icons, adjacentCell: true, cellDebug: false)
            } else {
                CalendarDayCell(day: targetDate, cellWidth: 63, cellHeight: 63, icons: icons, adjacentCell: true, cellDebug: false)
            }
        }
    }
}

private struct MonthlySummaryChart: View {
    let monthActivities: [(icon: String, count: Int)]
    
    var body: some View {
        Group {
            if !monthActivities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activities by Category")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Chart(monthActivities, id: \.icon) { item in
                        BarMark(
                            x: .value("Activity", item.icon),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(.blue)
                        .annotation(position: .top, alignment: .center) {
                            if item.count > 0 {
                                Text("\(item.count)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            if let icon = value.as(String.self) {
                                AxisValueLabel {
                                    Image(systemName: icon)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }
}


/// Wrapper so we don't extend Foundation.Date to Identifiable
private struct IdentifiableDate: Identifiable, Equatable {
    let id = UUID()
    let date: Date
}



// MARK: - Day Activity Sheet

private struct DayActivitySheet: View {
    let date: Date
    let entries: [ActivityHistory]
    let calendar: Calendar
    
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [Activity]
    
    @State private var isPresentingAddHistory = false
    @State private var selectedActivity: Activity? = nil
    @State private var newHistoryDate: Date = Date()
    
    @State private var pendingDelete: ActivityHistory? = nil
    @State private var showDeleteAlert: Bool = false
    
    private var title: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "No Activity History",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("No completed activities for this day.")
                        )
                    }
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(entries) { history in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: history.activity?.icon ?? "questionmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundStyle(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(history.activity?.name ?? "Unknown Activity")
                                    .font(.headline)
                                
                                Text(history.dateCompleted, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if let notes = history.activity?.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                pendingDelete = history
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete History?", isPresented: $showDeleteAlert, presenting: pendingDelete) { history in
                Button("Delete", role: .destructive) {
                    modelContext.delete(history)
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .activityDidChange, object: nil)
                    let success = UINotificationFeedbackGenerator()
                    success.notificationOccurred(.success)
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDelete = nil
                }
            } message: { _ in
                Text("This action cannot be undone.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedActivity = activities.first
                        newHistoryDate = date
                        isPresentingAddHistory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add History")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddHistory) {
            NavigationStack {
                Form {
                    Section("New History Entry") {
                        Picker("Activity", selection: $selectedActivity) {
                            ForEach(activities) { act in
                                Text(act.name).tag(Optional(act))
                            }
                        }
                        DatePicker("Completed On", selection: $newHistoryDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                .navigationTitle("Add History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isPresentingAddHistory = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let act = selectedActivity {
                                let entry = ActivityHistory(activity: act, dateCompleted: newHistoryDate)
                                modelContext.insert(entry)
                                try? modelContext.save()
                                NotificationCenter.default.post(name: .activityDidChange, object: nil)
                                isPresentingAddHistory = false
                            }
                        }
                    }
                }
                .onAppear {
                    if selectedActivity == nil { selectedActivity = activities.first }
                    newHistoryDate = date
                }
            }
        }
    }
}

#Preview {
    CalendarView()
}

