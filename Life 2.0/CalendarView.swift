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

struct CalendarView: View {
    let year: Int
    let month: Int // 1...12

    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var sheetDate: Date? = nil
    @Query private var historyEntries: [ActivityHistory]

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
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
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        cal.locale = Locale(identifier: "en_US_POSIX")
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
        let start = calendar.startOfDay(for: monthStart)
        let end = calendar.startOfDay(for: calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart)
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
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
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

    
    
    
    private func iconsGrid(for icons: [String],
                           cellWidth: CGFloat,
                           isLandscape: Bool,
                           dayCellHeight: CGFloat) -> some View {
        let iconCount = icons.count

        // Determine base icon size (portrait & general multi-icon layout)
        let maxIconSizePortrait = min(cellWidth - 8, 32) // fit within scrollview height and cell width
        let baseSize: CGFloat
        switch iconCount {
        case 0:
            baseSize = 0
        case 1:
            baseSize = maxIconSizePortrait   // single icon fills available space in portrait
        case 2...4:
            baseSize = min(maxIconSizePortrait * 0.8, 22)
        default:
            baseSize = min(maxIconSizePortrait * 0.6, 16)
        }

        // Single-icon landscape size: try to use as much of the day cell height as possible,
        // but don't exceed the cell width minus some padding.
        let singleLandscapeSize = min(max(dayCellHeight - 16, 0), cellWidth - 8)

        // Break into rows of up to 3 icons
        let rows: [[String]] = stride(from: 0, to: icons.count, by: 3).map { index in
            Array(icons[index..<min(index + 3, icons.count)])
        }

        
        var height: CGFloat = 0
        if verticalSizeClass == .compact {
            // Landscape
            height = 88
        } else {
            // Portrait
            height = 32
        }
        
        return ScrollView(.vertical, showsIndicators: true) {
            if iconCount == 1, let iconName = icons.first {
                // Portrait keeps existing behavior; landscape scales to fill the scrollview area.
                let iconSize = (isLandscape ? singleLandscapeSize : baseSize)

                HStack {
                    Spacer(minLength: 0)
                    Image(systemName: iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(.green)
                    Spacer(minLength: 0)
                }
            } else {
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
            }
        }
        // Fixed height so this view never forces the day cell to grow taller in portrait.
        // In landscape with a single icon, let the height grow to match the scaled icon.
        .frame(height: height)
        //.background(Color.yellow.opacity(0.3))
    }

var body: some View {
        NavigationStack {
            Group {
                GeometryReader { proxy in
                    let totalWidth = proxy.size.width
                    let dayCellWidth = totalWidth / 7.0
                    let dayCellHeight = dayCellWidth
                    let isLandscape = proxy.size.width > proxy.size.height

                    ScrollView(.vertical) {
                        LazyVGrid(columns: columns(for: totalWidth), spacing: 0) {
                        ForEach(cells, id: \.self) { cell in
                            switch cell {
                            case .header(let title):
                                ZStack {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(Color(.secondarySystemBackground))
                                    Text(title)
                                        .font(.headline)
                                }
                                .frame(height: 40)

                            case .adjacent(let d, _):
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color.gray.opacity(0.25))
                                        )
                                    Text("\(d)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                }
                                .frame(height: dayCellHeight)

                            case .day(let d):
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color.gray.opacity(0.3))
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(d)")
                                            .font(.headline)
                                            .padding(8)
                                            .foregroundStyle(.primary)

                                        let date = dateForCurrentMonth(day: d)
                                        let icons = iconsFor(date: date)
                                        if !icons.isEmpty {
                                            iconsGrid(for: icons, cellWidth: dayCellWidth, isLandscape: isLandscape, dayCellHeight: dayCellHeight)
                                                .padding(.horizontal, 6)
                                                .padding(.top, -8)
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    let date = dateForCurrentMonth(day: d)
                                    sheetDate = date
                                }
                                .frame(height: dayCellHeight)
                            }
                        }
                    }
                }
                }

            }
            .navigationTitle(monthName)
            .sheet(item: $sheetDate) { date in
                DayActivitySheet(
                    date: date,
                    entries: historyEntries(on: date),
                    calendar: calendar
                )
            }

            ///
///
            .toolbar {
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
                ToolbarSpacer()
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
            }

            ///
        }
    }
}



// MARK: - Day Activity Sheet

private struct DayActivitySheet: View {
    let date: Date
    let entries: [ActivityHistory]
    let calendar: Calendar

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
                    ContentUnavailableView(
                        "No Activity History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("No completed activities for this day.")
                    )
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
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Allow Date to be used with .sheet(item:)
extension Date: Identifiable {
    public var id: Date { self }
}

#Preview {
    CalendarView()
}
