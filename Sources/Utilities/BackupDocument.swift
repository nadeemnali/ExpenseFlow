import Foundation
import UniformTypeIdentifiers
import SwiftUI

struct BackupPackage: Codable {
    let createdAt: Date
    let expenses: [Expense]
    let recurringExpenses: [RecurringExpense]
    let settings: AppSettings
    let customCategories: [CustomCategory]
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var package: BackupPackage

    init(package: BackupPackage) {
        self.package = package
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoded = try JSONDecoder().decode(BackupPackage.self, from: data)
        self.package = decoded
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(package)
        return .init(regularFileWithContents: data)
    }
}
