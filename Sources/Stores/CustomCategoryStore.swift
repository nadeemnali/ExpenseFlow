import Foundation
import Combine

struct CustomCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}

final class CustomCategoryStore: ObservableObject {
    @Published private(set) var categories: [CustomCategory] = []

    private let storageKey = "ExpenseFlow.customCategories"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        $categories
            .dropFirst()
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }

    func add(name: String, colorHex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if categories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return
        }
        categories.append(CustomCategory(name: trimmed, colorHex: colorHex))
    }

    func delete(_ category: CustomCategory) {
        categories.removeAll { $0.id == category.id }
    }

    func replaceAll(_ categories: [CustomCategory]) {
        self.categories = categories
    }

    func category(named name: String) -> CustomCategory? {
        categories.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    func nextColorHex() -> String {
        let palette = Self.palette
        let index = categories.count % palette.count
        return palette[index]
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([CustomCategory].self, from: data) {
            categories = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static let palette: [String] = [
        "#FF6F59",
        "#2EC4B6",
        "#1B9AAA",
        "#FFC857",
        "#F05D5E",
        "#F79D84",
        "#4FB0C6",
        "#5C7AEA",
        "#94A3B8"
    ]
}
