import Foundation
import os.log

enum LogCategory: String {
    case auth = "com.expenseflow.auth"
    case storage = "com.expenseflow.storage"
    case ui = "com.expenseflow.ui"
    case general = "com.expenseflow.general"
}

struct AppLogger {
    static func log(
        _ message: String,
        category: LogCategory = .general,
        level: OSLogType = .info
    ) {
        let logger = os.Logger(subsystem: category.rawValue, category: "")
        logger.log(level: level, "\(message)")
    }
    
    static func error(
        _ message: String,
        error: Error? = nil,
        category: LogCategory = .general
    ) {
        let logger = os.Logger(subsystem: category.rawValue, category: "")
        if let error = error {
            logger.error("\(message): \(error.localizedDescription)")
        } else {
            logger.error("\(message)")
        }
    }
    
    static func debug(
        _ message: String,
        category: LogCategory = .general
    ) {
        #if DEBUG
        let logger = os.Logger(subsystem: category.rawValue, category: "")
        logger.debug("\(message)")
        #endif
    }
}
