import SwiftUI
import Combine
import os.log

final class SettingsStore: ObservableObject {
    @Published var monthlyBudget: Double = 1200
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @Published var notificationsEnabled: Bool = true
    @Published var startOfWeek: WeekStart = .monday
    @Published var colorScheme: ColorSchemeOption = .system
    @Published var saveError: String?

    private let settingsKey = "ExpenseFlow.settings"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        Publishers.CombineLatest4($monthlyBudget, $currencyCode, $notificationsEnabled, $startOfWeek)
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)

        $colorScheme
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }

    var preferredColorScheme: ColorScheme? {
        switch colorScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            AppLogger.log("No saved settings found, using defaults", category: .storage, level: .info)
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
            
            // Validate settings
            guard decoded.monthlyBudget > 0 else {
                throw SettingsError.invalidBudget
            }
            guard !decoded.currencyCode.isEmpty else {
                throw SettingsError.invalidCurrency
            }
            
            monthlyBudget = decoded.monthlyBudget
            currencyCode = decoded.currencyCode
            notificationsEnabled = decoded.notificationsEnabled
            startOfWeek = decoded.startOfWeek
            colorScheme = decoded.colorScheme
            
            AppLogger.log("Settings loaded successfully", category: .storage, level: .info)
        } catch {
            AppLogger.error("Failed to load settings", error: error, category: .storage)
            saveError = "Could not load settings. Using defaults."
        }
    }

    private func save() {
        let settings = AppSettings(
            monthlyBudget: monthlyBudget,
            currencyCode: currencyCode,
            notificationsEnabled: notificationsEnabled,
            startOfWeek: startOfWeek,
            colorScheme: colorScheme
        )
        
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
            saveError = nil
            AppLogger.debug("Settings saved successfully", category: .storage)
        } catch {
            AppLogger.error("Failed to save settings", error: error, category: .storage)
            saveError = "Could not save settings. Changes may be lost."
        }
    }
    
    enum SettingsError: LocalizedError {
        case invalidBudget
        case invalidCurrency
        
        var errorDescription: String? {
            switch self {
            case .invalidBudget:
                return "Budget must be greater than zero"
            case .invalidCurrency:
                return "Invalid currency code"
            }
        }
    }
}

struct AppSettings: Codable {
    let monthlyBudget: Double
    let currencyCode: String
    let notificationsEnabled: Bool
    let startOfWeek: WeekStart
    let colorScheme: ColorSchemeOption
}

enum WeekStart: String, CaseIterable, Codable, Identifiable {
    case sunday
    case monday

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        }
    }
}

enum ColorSchemeOption: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
