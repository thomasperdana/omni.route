import SwiftUI

struct StatusCardView: View {
    @ObservedObject var appState: AppState
    
    var formattedUptime: String {
        let sec = appState.uptimeSeconds
        let hrs = sec / 3600
        let mins = (sec % 3600) / 60
        let s = sec % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, s)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Card 1: Server Status
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(appState.status.color)
                        .frame(width: 10, height: 10)
                    Text("Gateway Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if appState.status == .running {
                        Text(formattedUptime)
                            .font(.caption2.monospaced())
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(appState.status.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: appState.isHealthy ? "checkmark.shield.fill" : "shield.slash")
                        .font(.caption2)
                        .foregroundColor(appState.isHealthy ? .green : .secondary)
                    Text(appState.isHealthy ? "Health: Online" : "Health: Offline")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // Card 2: Endpoint URL
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("OpenAI Endpoint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        appState.copyApiEndpoint()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                    .help("Copy API endpoint to clipboard")
                }
                
                Text("http://localhost:\(appState.activePort)/v1")
                    .font(.subheadline.monospaced())
                    .lineLimit(1)
                
                Text("Compatible with Cursor, Cline, Claude Code")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // Card 3: Process Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(.purple)
                        .font(.caption)
                    Text("Process Info")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                if let pid = appState.pid {
                    Text("PID: \(pid)")
                        .font(.headline.monospaced())
                } else {
                    Text("Inactive")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Text("Port: \(appState.activePort)")
                    .font(.caption2.monospaced())
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
