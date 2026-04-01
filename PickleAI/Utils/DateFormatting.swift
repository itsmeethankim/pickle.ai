import Foundation

extension Date {
    func relativeFormatted() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.second, .minute, .hour, .day, .weekOfYear],
            from: self,
            to: now
        )

        if let weeks = components.weekOfYear, weeks >= 1 {
            return shortFormatted()
        } else if let days = components.day {
            if days >= 2 {
                return "\(days) days ago"
            } else if days == 1 {
                return "Yesterday"
            }
        }

        if let hours = components.hour, hours >= 1 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }

        if let minutes = components.minute, minutes >= 1 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        }

        return "Just now"
    }

    func shortFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
