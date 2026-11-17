import SwiftUI

struct ConsoleView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Console Toolbar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Console Output")
                        .font(.caption.bold())
                }
                
                Spacer()
                
                // Filter search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                    TextField("Filter output...", text: $appState.logSearchQuery)
                        .textFieldStyle(.plain)
                        .font(.caption)
                    if !appState.logSearchQuery.isEmpty {
                        Button(action: { appState.logSearchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.textBackgroundColor).opacity(0.6))
                .cornerRadius(6)
                .frame(width: 180)
                
                // Auto scroll toggle
                Toggle(isOn: $appState.isAutoScrollEnabled) {
                    Text("Auto-scroll")
                        .font(.caption)
                }
                .toggleStyle(.checkbox)
                
                // Copy Logs Button
                Button(action: {
                    appState.copyLogs()
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Copy all terminal logs to clipboard")
                
                // Clear Button
                Button(action: {
                    appState.clearLogs()
                }) {
                    Label("Clear", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Clear console logs")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Console Logs Scroll Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if appState.filteredLogs.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "terminal")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("No logs yet. Click 'Start Gateway' or 'Install OmniRoute' to begin.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .padding()
                        } else {
                            ForEach(appState.filteredLogs) { entry in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(entry.formattedTimestamp)
                                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                                        .foregroundColor(.secondary.opacity(0.7))
                                        .frame(width: 78, alignment: .leading)
                                    
                                    Text(entry.text)
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .foregroundColor(entry.type.color)
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .id(entry.id)
                            }
                        }
                    }
                    .padding(10)
                }
                .background(Color(red: 0.08, green: 0.09, blue: 0.12))
                .onChange(of: appState.logs.count) { _ in
                    if appState.isAutoScrollEnabled, let lastId = appState.filteredLogs.last?.id {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Bottom Status Bar
            HStack {
                Text("\(appState.filteredLogs.count) log lines")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if let path = appState.omniroutePath {
                    Text("CLI: \(path)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
