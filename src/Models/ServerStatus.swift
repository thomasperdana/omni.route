import Foundation
import SwiftUI

enum ServerStatus: Equatable {
    case stopped
    case installing
    case starting
    case running
    case error(String)
    
    var title: String {
        switch self {
        case .stopped: return "Stopped"
        case .installing: return "Installing npm package..."
        case .starting: return "Starting Gateway..."
        case .running: return "Running"
        case .error(let msg): return "Error: \(msg)"
        }
    }
    
    var color: Color {
        switch self {
        case .stopped: return .gray
        case .installing: return .orange
        case .starting: return .yellow
        case .running: return .green
        case .error: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .stopped: return "stop.circle.fill"
        case .installing: return "arrow.down.circle.fill"
        case .starting: return "clock.arrow.2.circlepath"
        case .running: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}
