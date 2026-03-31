import Foundation
import Vision
import UIKit

class BillOCRService {
    static let shared = BillOCRService()
    
    private init() {}
    
    func extractBillData(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let rawText = try await recognizeText(from: cgImage)
        let parsedData = parseOCRText(rawText)
        
        return OCRResult(
            vendor: parsedData.vendor,
            amount: parsedData.amount,
            date: parsedData.date,
            description: parsedData.description,
            rawText: rawText,
            confidence: parsedData.confidence
        )
    }
    
    private func recognizeText(from cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextDetected)
                    return
                }
                
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
    
    private func parseOCRText(_ text: String) -> ParsedOCRData {
        let lines = text.split(separator: "\n").map(String.init)
        
        var vendor = extractVendor(from: lines)
        var amount = extractAmount(from: text)
        var date = extractDate(from: text)
        var description: String?
        var confidence = 0.95
        
        if vendor.isEmpty {
            vendor = "Unknown Vendor"
            confidence -= 0.3
        }
        
        if amount <= 0 {
            amount = 0
            confidence -= 0.3
        }
        
        if date == Date(timeIntervalSince1970: 0) {
            date = Date()
            confidence -= 0.2
        }
        
        confidence = max(0.0, min(1.0, confidence))
        
        return ParsedOCRData(
            vendor: vendor,
            amount: amount,
            date: date,
            description: description,
            confidence: confidence
        )
    }
    
    private func extractVendor(from lines: [String]) -> String {
        let validLines = lines
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .filter { !isNumeric($0) }
            .filter { !isDate($0) }
        
        if let firstLine = validLines.first, firstLine.count > 2 && firstLine.count < 100 {
            return firstLine.trimmingCharacters(in: .whitespaces)
        }
        
        return ""
    }
    
    private func extractAmount(from text: String) -> Decimal {
        let currencyPatterns = [
            "\\$\\s*(\\d+(?:[,.]\\d{2})?)",
            "(\\d+(?:[,.]\\d{2})?)\\s*(?:USD|dollar)",
            "(?:total|amount|subtotal)\\s*[:\\-]?\\s*\\$?\\s*(\\d+(?:[,.]\\d{2})?)"
        ]
        
        for pattern in currencyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountStr = String(text[range])
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: "$", with: "")
                
                if let amount = Decimal(string: amountStr) {
                    return amount
                }
            }
        }
        
        return 0
    }
    
    private func extractDate(from text: String) -> Date {
        let datePatterns = [
            "(\\d{1,2})[/-](\\d{1,2})[/-](\\d{2,4})",
            "(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\\s,]+(\\d{1,2})[\\s,]+(\\d{4})"
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let dateString = Range(match.range, in: text) {
                    let dateStr = String(text[dateString])
                    if let date = parseDate(dateStr) {
                        return date
                    }
                }
            }
        }
        
        return Date()
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "MM/dd/yyyy",
            "MM-dd-yyyy",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "M/d/yy",
            "M-d-yy",
            "MMMM dd, yyyy",
            "MMM dd, yyyy",
            "MMMM d, yyyy",
            "MMM d, yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func isNumeric(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        return trimmed.allSatisfy { $0.isNumber || $0 == "." || $0 == "," }
    }
    
    private func isDate(_ string: String) -> Bool {
        let patterns = [
            "\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4}",
            "(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2}"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) != nil {
                return true
            }
        }
        
        return false
    }
}

private struct ParsedOCRData {
    let vendor: String
    let amount: Decimal
    let date: Date
    let description: String?
    let confidence: Double
}

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(Error)
    case noTextDetected
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process image"
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .noTextDetected:
            return "No text detected in image"
        case .parsingFailed(let message):
            return "Failed to parse bill: \(message)"
        }
    }
}
