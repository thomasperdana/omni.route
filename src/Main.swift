import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?
    
    func applicationWillTerminate(_ notification: Notification) {
        appState?.stopServer()
    }
}

@main
struct OmniRouteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    init() {
        // App initialization
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .onAppear {
                    appDelegate.appState = appState
                    if appState.autoStartOnLaunch && appState.isOmnirouteInstalled {
                        appState.startServer()
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 880, height: 640)
        
        MenuBarExtra("OmniRoute", systemImage: appState.status == .running ? "point.3.connected.trianglepath.dotted" : "circle.dotted") {
            VStack {
                Text("OmniRoute: \(appState.status.title)")
                    .font(.caption.bold())
                
                Divider()
                
                if appState.status == .running {
                    Button("Stop Gateway") {
                        appState.stopServer()
                    }
                    Button("Open Web Dashboard") {
                        appState.openDashboard()
                    }
                    Button("Copy Endpoint URL") {
                        appState.copyApiEndpoint()
                    }
                } else {
                    Button("Start Gateway") {
                        appState.startServer()
                    }
                    if !appState.isOmnirouteInstalled {
                        Button("Install OmniRoute") {
                            appState.installOmniroute()
                        }
                    }
                }
                
                Divider()
                
                Button("Quit OmniRoute") {
                    appState.stopServer()
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}
