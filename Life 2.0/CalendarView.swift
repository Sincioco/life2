// ————————————————————————————————————————————————————————————————————————————————————————————————————
//                                         Life 2.0 - Calendar View
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Programmed By:  Louiery R. Sincioco                                                     Version: 1.0
// Programmed Date:  November 21, 2025                                                      For: iOS 26
// ————————————————————————————————————————————————————————————————————————————————————————————————————
// Purpose:  Calendar view of activities.
// ————————————————————————————————————————————————————————————————————————————————————————————————————
import SwiftUI

struct CalendarView: View {
    let year: Int
    let month: Int // 1...12

    @State private var selectedYear: Int
    @State private var selectedMonth: Int

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

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 63.0, maximum: 120), spacing: 0), count: 7)
    }

    private var gridHeight: CGFloat { 40 + 100 * 6 + 16 } // header + 6 rows + vertical padding

    enum Cell: Hashable {
        case header(String)
        case adjacent(Int, Bool) // (day, isPrevious)
        case day(Int)
    }

    var body: some View {
        NavigationStack {
            Group {

                ScrollView(.vertical) {
                    LazyVGrid(columns: columns, spacing: 0) {
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
                                .frame(height: 70)

                            case .day(let d):
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color.gray.opacity(0.3))
                                        )
                                    Text("\(d)")
                                        .font(.headline)
                                        .padding(8)
                                        .foregroundStyle(.primary)
                                }
                                .frame(height: 70)
                            }
                        }
                    }
                    .padding(8)
                }

            }
            .navigationTitle(monthName)

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

#Preview {
    CalendarView()
}
