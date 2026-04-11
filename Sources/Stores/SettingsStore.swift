import SwiftUI
import Combine
import os.log

final class SettingsStore: ObservableObject {
    @Published var monthlyBudget: Double = 1200
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @Published var notificationsEnabled: Bool = true
    @Published var budgetAlertsEnabled: Bool = true
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

        $budgetAlertsEnabled
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

    var snapshot: AppSettings {
        AppSettings(
            monthlyBudget: monthlyBudget,
            currencyCode: currencyCode,
            notificationsEnabled: notificationsEnabled,
            budgetAlertsEnabled: budgetAlertsEnabled,
            startOfWeek: startOfWeek,
            colorScheme: colorScheme
        )
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
        budgetAlertsEnabled = decoded.budgetAlertsEnabled
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
            budgetAlertsEnabled: budgetAlertsEnabled,
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

    func apply(_ settings: AppSettings) {
        monthlyBudget = settings.monthlyBudget
        currencyCode = settings.currencyCode
        notificationsEnabled = settings.notificationsEnabled
        budgetAlertsEnabled = settings.budgetAlertsEnabled
        startOfWeek = settings.startOfWeek
        colorScheme = settings.colorScheme
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
    let budgetAlertsEnabled: Bool
    let startOfWeek: WeekStart
    let colorScheme: ColorSchemeOption

    enum CodingKeys: String, CodingKey {
        case monthlyBudget
        case currencyCode
        case notificationsEnabled
        case budgetAlertsEnabled
        case startOfWeek
        case colorScheme
    }

    init(
        monthlyBudget: Double,
        currencyCode: String,
        notificationsEnabled: Bool,
        budgetAlertsEnabled: Bool,
        startOfWeek: WeekStart,
        colorScheme: ColorSchemeOption
    ) {
        self.monthlyBudget = monthlyBudget
        self.currencyCode = currencyCode
        self.notificationsEnabled = notificationsEnabled
        self.budgetAlertsEnabled = budgetAlertsEnabled
        self.startOfWeek = startOfWeek
        self.colorScheme = colorScheme
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyBudget = try container.decode(Double.self, forKey: .monthlyBudget)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        budgetAlertsEnabled = try container.decodeIfPresent(Bool.self, forKey: .budgetAlertsEnabled) ?? true
        startOfWeek = try container.decode(WeekStart.self, forKey: .startOfWeek)
        colorScheme = try container.decode(ColorSchemeOption.self, forKey: .colorScheme)
    }
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
