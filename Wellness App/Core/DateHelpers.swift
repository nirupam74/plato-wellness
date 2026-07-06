//
//  DateHelpers.swift
//  Wellness App
//
//  Small calendar conveniences used across stores and trend views.
//

import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Days offset from this date (negative for the past).
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Short weekday + day, for chart axes and lists.
    var shortLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE d"
        return f.string(from: self)
    }
}
