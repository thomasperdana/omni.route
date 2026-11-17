import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Top App Bar
            HStack(spacing: 12) {
                // App Logo & Info
                HStack(spacing: 8) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.title2.bold())
                        .foregroundColor(.indigo)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("OmniRoute")
                                .font(.headline.bold())
                            
                            // Status Pill
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(appState.status.color)
                                    .frame(width: 8, height: 8)
                                Text(appState.status.title)
                                    .font(.caption2.bold())
                                    .foregroundColor(appState.status.color)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(appState.status.color.opacity(0.12))
                            .cornerRadius(12)
                        }
                        
                        Text("OpenAI-Compatible AI Gateway & Router")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Primary Action: Start / Stop
                if appState.status == .running {
                    Button(action: {
                        appState.stopServer()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                            Text("Stop Gateway")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Stop running OmniRoute gateway")
                } else if appState.status == .starting {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Starting...")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                } else if appState.status == .installing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Installing npm package...")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                } else {
                    Button(action: {
                        appState.startServer()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Start Gateway")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Start OmniRoute gateway server")
                }
                
                // Install / Reinstall button
                Button(action: {
                    appState.installOmniroute()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                        Text(appState.isOmnirouteInstalled ? "Update" : "Install")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(appState.status == .installing)
                .help("Run 'npm install -g omniroute'")
                
                // Open Web Dashboard
                Button(action: {
                    appState.openDashboard()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "safari")
                        Text("Web UI")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .help("Open Web Dashboard in default browser (http://localhost:\(appState.activePort))")
                
                // Copy Endpoint Button
                Button(action: {
                    appState.copyApiEndpoint()
                    appState.showCopiedAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        appState.showCopiedAlert = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: appState.showCopiedAlert ? "checkmark" : "doc.on.doc")
                        Text(appState.showCopiedAlert ? "Copied!" : "Copy URL")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .help("Copy API endpoint to clipboard")
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Selector
            HStack {
                Picker("", selection: $appState.selectedTab) {
                    Text("Dashboard & Console").tag(0)
                    Text("Integrations Guide").tag(1)
                    Text("Settings").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
            
            Divider()
            
            // Content Views
            VStack(spacing: 0) {
                switch appState.selectedTab {
                case 0:
                    VStack(spacing: 12) {
                        // Installation banner if missing
                        if !appState.isOmnirouteInstalled && appState.status != .installing {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("OmniRoute is not installed on this Mac.")
                                        .bold()
                                        .font(.subheadline)
                                    Text("Click 'Install' above or run 'npm install -g omniroute' to get started.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Install Now") {
                                    appState.installOmniroute()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding(10)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        }
                        
                        // Status Metrics
                        StatusCardView(appState: appState)
                        
                        // Terminal Logs
                        ConsoleView(appState: appState)
                    }
                    .padding(14)
                    
                case 1:
                    IntegrationsView(appState: appState)
                    
                case 2:
                    SettingsView(appState: appState)
                    
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 780, minHeight: 560)
    }
}
