import Foundation

struct OCRResult: Codable, Identifiable {
    let id: UUID
    let vendor: String
    let amount: Decimal
    let date: Date
    let description: String?
    let rawText: String
    let confidence: Double
    let scannedAt: Date
    
    init(
        vendor: String,
        amount: Decimal,
        date: Date,
        description: String? = nil,
        rawText: String,
        confidence: Double = 0.95,
        id: UUID = UUID(),
        scannedAt: Date = Date()
    ) {
        self.id = id
        self.vendor = vendor
        self.amount = amount
        self.date = date
        self.description = description
        self.rawText = rawText
        self.confidence = confidence
        self.scannedAt = scannedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, vendor, amount, date, description, rawText, confidence, scannedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.vendor = try container.decode(String.self, forKey: .vendor)
        
        let amountString = try container.decode(String.self, forKey: .amount)
        self.amount = Decimal(string: amountString) ?? 0
        
        self.date = try container.decode(Date.self, forKey: .date)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.rawText = try container.decode(String.self, forKey: .rawText)
        self.confidence = try container.decode(Double.self, forKey: .confidence)
        self.scannedAt = try container.decode(Date.self, forKey: .scannedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(vendor, forKey: .vendor)
        try container.encode(amount.description, forKey: .amount)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(rawText, forKey: .rawText)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(scannedAt, forKey: .scannedAt)
    }
}

extension OCRResult {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$\(amount)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
