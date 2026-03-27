import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food
    case transport
    case utilities
    case entertainment
    case health
    case shopping
    case travel
    case education
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .food: return "Food"
        case .transport: return "Transport"
        case .utilities: return "Utilities"
        case .entertainment: return "Fun"
        case .health: return "Health"
        case .shopping: return "Shopping"
        case .travel: return "Travel"
        case .education: return "Education"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .shopping: return "bag.fill"
        case .travel: return "airplane"
        case .education: return "book.fill"
        case .other: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .food: return AppTheme.coral
        case .transport: return AppTheme.ocean
        case .utilities: return AppTheme.mango
        case .entertainment: return Color(hex: "#8AD1C2")
        case .health: return Color(hex: "#F05D5E")
        case .shopping: return Color(hex: "#F79D84")
        case .travel: return Color(hex: "#4FB0C6")
        case .education: return Color(hex: "#5C7AEA")
        case .other: return Color(hex: "#94A3B8")
        }
    }
}
