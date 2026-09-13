import Foundation
import UIKit
import os.log

final class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private let fileManager = FileManager.default
    private let imageCacheDirectoryName = "ExpenseReceiptImages"
    
    private var imageCacheDirectory: URL? {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let cacheDir = documents.appendingPathComponent(imageCacheDirectoryName, isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            do {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            } catch {
                AppLogger.error("Failed to create image cache directory", error: error, category: .storage)
                return nil
            }
        }
        return cacheDir
    }
    
    private init() {}
    
    func saveReceiptImage(_ image: UIImage, for expenseId: UUID) -> String? {
        guard let cacheDir = imageCacheDirectory else {
            AppLogger.log("Image cache directory not available", category: .storage, level: .default)
            return nil
        }
        
        let fileName = "\(expenseId.uuidString).jpg"
        let fileURL = cacheDir.appendingPathComponent(fileName)
        
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            AppLogger.log("Failed to convert image to JPEG", category: .storage, level: .default)
            return nil
        }
        
        do {
            try jpegData.write(to: fileURL, options: .atomic)
            AppLogger.log("Saved receipt image for expense: \(expenseId)", category: .storage, level: .debug)
            return fileName
        } catch {
            AppLogger.error("Failed to save receipt image", error: error, category: .storage)
            return nil
        }
    }
    
    func retrieveReceiptImage(fileName: String) -> UIImage? {
        guard let cacheDir = imageCacheDirectory else {
            return nil
        }
        
        let fileURL = cacheDir.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            AppLogger.log("Receipt image file not found: \(fileName)", category: .storage, level: .debug)
            return nil
        }
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            AppLogger.error("Failed to load receipt image", error: error, category: .storage)
            return nil
        }
    }
    
    func deleteReceiptImage(fileName: String) {
        guard let cacheDir = imageCacheDirectory else {
            return
        }
        
        let fileURL = cacheDir.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            AppLogger.log("Deleted receipt image: \(fileName)", category: .storage, level: .debug)
        } catch {
            AppLogger.error("Failed to delete receipt image", error: error, category: .storage)
        }
    }
    
    func deleteAllReceiptImages() {
        guard let cacheDir = imageCacheDirectory else {
            return
        }
        
        do {
            try fileManager.removeItem(at: cacheDir)
            try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            AppLogger.log("Cleared all receipt images", category: .storage, level: .debug)
        } catch {
            AppLogger.error("Failed to clear receipt images", error: error, category: .storage)
        }
    }
}
