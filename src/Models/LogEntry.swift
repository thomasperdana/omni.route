import Foundation
import SwiftUI

enum LogType {
    case info
    case stdout
    case stderr
    case error
    case success
    
    var color: Color {
        switch self {
        case .info: return Color(red: 0.5, green: 0.7, blue: 1.0)
        case .stdout: return Color(red: 0.85, green: 0.85, blue: 0.9)
        case .stderr: return Color(red: 1.0, green: 0.7, blue: 0.4)
        case .error: return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .success: return Color(red: 0.4, green: 0.9, blue: 0.5)
        }
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let type: LogType
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}
