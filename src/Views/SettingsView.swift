import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section 1: Server Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Label("Server Configuration", systemImage: "server.rack")
                        .font(.headline)
                    
                    HStack {
                        Text("Port:")
                            .frame(width: 140, alignment: .leading)
                        TextField("20128", value: $appState.port, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Text("(Default: 20128)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Custom CLI Flags:")
                            .frame(width: 140, alignment: .leading)
                        TextField("e.g. --log --no-recovery", text: $appState.customArgs)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Toggle("Automatically open dashboard in browser when server starts", isOn: $appState.autoOpenBrowser)
                        .toggleStyle(.checkbox)
                        .font(.subheadline)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                
                // Section 2: Environment & Dependencies
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("System Environment & Runtime", systemImage: "gearshape.2")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            appState.refreshEnvironment()
                        }) {
                            Label("Re-detect", systemImage: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Divider()
                    
                    // Node.js
                    HStack {
                        Image(systemName: appState.isNodeInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(appState.isNodeInstalled ? .green : .red)
                        Text("Node.js:")
                            .bold()
                            .frame(width: 90, alignment: .leading)
                        if appState.isNodeInstalled {
                            Text(appState.nodeVersion ?? "Installed")
                                .font(.caption.monospaced())
                            Text("(\(appState.nodePath ?? ""))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Not detected in PATH")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // npm
                    HStack {
                        Image(systemName: appState.isNpmInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(appState.isNpmInstalled ? .green : .red)
                        Text("npm:")
                            .bold()
                            .frame(width: 90, alignment: .leading)
                        if appState.isNpmInstalled {
                            Text("v\(appState.npmVersion ?? "")")
                                .font(.caption.monospaced())
                            Text("(\(appState.npmPath ?? ""))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Not detected in PATH")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // OmniRoute
                    HStack {
                        Image(systemName: appState.isOmnirouteInstalled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(appState.isOmnirouteInstalled ? .green : .orange)
                        Text("OmniRoute:")
                            .bold()
                            .frame(width: 90, alignment: .leading)
                        if appState.isOmnirouteInstalled {
                            Text(appState.omnirouteVersion ?? "Installed")
                                .font(.caption.monospaced())
                            Text("(\(appState.omniroutePath ?? ""))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Not installed. Click 'Install OmniRoute' in toolbar.")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Custom Bin Directory:")
                            .frame(width: 140, alignment: .leading)
                        TextField("Optional custom path (e.g. /usr/local/bin)", text: $appState.customNodeDir)
                            .textFieldStyle(.roundedBorder)
                    }
                    Text("Leave empty to use auto-detected system PATH.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                
                // Section 3: About
                VStack(alignment: .leading, spacing: 8) {
                    Label("About OmniRoute GUI", systemImage: "info.circle")
                        .font(.headline)
                    Text("OmniRoute is an OpenAI-compatible smart AI gateway and router with automatic fallback, load balancing, and provider aggregation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("GUI Version 1.0.0 (Native SwiftUI macOS App)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            }
            .padding(16)
        }
    }
}
