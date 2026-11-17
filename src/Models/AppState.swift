import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    // Navigation & UI State
    @Published var selectedTab: Int = 0
    @Published var showCopiedAlert: Bool = false
    @Published var copiedSnippetId: UUID? = nil
    
    // Environment & Detection
    @Published var isNodeInstalled: Bool = false
    @Published var nodePath: String? = nil
    @Published var nodeVersion: String? = nil
    
    @Published var isNpmInstalled: Bool = false
    @Published var npmPath: String? = nil
    @Published var npmVersion: String? = nil
    
    @Published var isOmnirouteInstalled: Bool = false
    @Published var omniroutePath: String? = nil
    @Published var omnirouteVersion: String? = nil
    
    // Server Lifecycle State
    @Published var status: ServerStatus = .stopped
    @Published var pid: Int32? = nil
    @Published var isHealthy: Bool = false
    @Published var uptimeSeconds: Int = 0
    @Published var activePort: Int = 20128
    
    // User Settings
    @Published var port: Int = 20128
    @Published var customNodeDir: String = ""
    @Published var customArgs: String = ""
    @Published var autoOpenBrowser: Bool = true
    @Published var autoStartOnLaunch: Bool = false
    
    // Live Terminal Logs
    @Published var logs: [LogEntry] = []
    @Published var logSearchQuery: String = ""
    @Published var isAutoScrollEnabled: Bool = true
    
    // Active Processes
    private var serverProcess: Process?
    private var installProcess: Process?
    private var healthCheckTimer: Timer?
    private var uptimeTimer: Timer?
    
    private var serverOutputBuffer: String = ""
    private var installOutputBuffer: String = ""
    
    init() {
        refreshEnvironment()
        appendLog("[System] OmniRoute macOS GUI initialized", type: .info)
        if isOmnirouteInstalled {
            appendLog("[System] OmniRoute CLI ready at: \(omniroutePath ?? "") (\(omnirouteVersion ?? ""))", type: .success)
        } else {
            appendLog("[System] OmniRoute CLI not detected. Click 'Install OmniRoute' to install.", type: .info)
        }
    }
    
    var filteredLogs: [LogEntry] {
        if logSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return logs
        }
        return logs.filter { $0.text.localizedCaseInsensitiveContains(logSearchQuery) }
    }
    
    func refreshEnvironment() {
        let node = EnvironmentHelper.checkNode()
        self.isNodeInstalled = node.installed
        self.nodePath = node.path
        self.nodeVersion = node.version
        
        let npm = EnvironmentHelper.checkNpm()
        self.isNpmInstalled = npm.installed
        self.npmPath = npm.path
        self.npmVersion = npm.version
        
        let omni = EnvironmentHelper.checkOmniroute()
        self.isOmnirouteInstalled = omni.installed
        self.omniroutePath = omni.path
        self.omnirouteVersion = omni.version
    }
    
    func appendLog(_ text: String, type: LogType = .stdout) {
        DispatchQueue.main.async {
            // Strip ANSI codes
            let cleaned = text.replacingOccurrences(of: #"\x1B\[[0-?]*[ -/]*[@-~]"#, with: "", options: .regularExpression)
            let entry = LogEntry(timestamp: Date(), text: cleaned, type: type)
            self.logs.append(entry)
            if self.logs.count > 2500 {
                self.logs.removeFirst(500)
            }
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func copyLogs() {
        let text = logs.map { "[\($0.formattedTimestamp)] \($0.text)" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    // MARK: - npm install -g omniroute
    func installOmniroute() {
        guard status != .installing else { return }
        
        guard let npmExec = EnvironmentHelper.findExecutable("npm", customPath: customNodeDir.isEmpty ? nil : "\(customNodeDir)/npm") else {
            appendLog("[Error] 'npm' was not found on your system. Please install Node.js first.", type: .error)
            status = .error("npm not found")
            return
        }
        
        status = .installing
        appendLog("------------------------------------------------------------", type: .info)
        appendLog("[Installer] Running command: npm install -g omniroute", type: .info)
        appendLog("[Installer] Using npm at: \(npmExec)", type: .info)
        appendLog("------------------------------------------------------------", type: .info)
        
        let proc = Process()
        proc.launchPath = npmExec
        proc.arguments = ["install", "-g", "omniroute"]
        
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = EnvironmentHelper.getAugmentedPath()
        proc.environment = env
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        
        self.installProcess = proc
        
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            if let str = String(data: data, encoding: .utf8) {
                self.handleInstallOutput(str, isError: false)
            }
        }
        
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            if let str = String(data: data, encoding: .utf8) {
                self.handleInstallOutput(str, isError: true)
            }
        }
        
        proc.terminationHandler = { [weak self] p in
            guard let self = self else { return }
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            
            DispatchQueue.main.async {
                self.installProcess = nil
                self.refreshEnvironment()
                
                if p.terminationStatus == 0 {
                    self.status = .stopped
                    self.appendLog("------------------------------------------------------------", type: .success)
                    self.appendLog("[Installer] ✅ omniroute installed successfully!", type: .success)
                    self.appendLog("[Installer] Version: \(self.omnirouteVersion ?? "latest")", type: .success)
                    self.appendLog("------------------------------------------------------------", type: .success)
                } else {
                    self.status = .error("npm install failed (code \(p.terminationStatus))")
                    self.appendLog("[Installer] ❌ npm install exited with status \(p.terminationStatus)", type: .error)
                }
            }
        }
        
        do {
            try proc.run()
        } catch {
            status = .error(error.localizedDescription)
            appendLog("[Installer] Failed to launch npm: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func handleInstallOutput(_ chunk: String, isError: Bool) {
        installOutputBuffer += chunk
        while let newlineRange = installOutputBuffer.range(of: "\n") {
            let line = String(installOutputBuffer[..<newlineRange.lowerBound])
            installOutputBuffer.removeSubrange(...newlineRange.lowerBound)
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                appendLog(line, type: isError ? .stderr : .stdout)
            }
        }
    }
    
    // MARK: - omniroute (Server Lifecycle)
    func startServer() {
        guard status == .stopped || status == .error("") else { return }
        
        guard let omniExec = EnvironmentHelper.findExecutable("omniroute", customPath: customNodeDir.isEmpty ? nil : "\(customNodeDir)/omniroute") else {
            appendLog("[Error] 'omniroute' is not installed or not in PATH.", type: .error)
            appendLog("[Tip] Click 'Install OmniRoute' to install it via npm.", type: .info)
            status = .error("omniroute not installed")
            return
        }
        
        status = .starting
        activePort = port
        uptimeSeconds = 0
        isHealthy = false
        
        appendLog("============================================================", type: .info)
        appendLog("[OmniRoute] Launching gateway: omniroute serve --port \(activePort)", type: .info)
        appendLog("[OmniRoute] Executable: \(omniExec)", type: .info)
        appendLog("============================================================", type: .info)
        
        let proc = Process()
        proc.launchPath = omniExec
        
        var args = ["serve", "--port", String(activePort)]
        if !customArgs.trimmingCharacters(in: .whitespaces).isEmpty {
            let extra = customArgs.split(separator: " ").map(String.init)
            args.append(contentsOf: extra)
        }
        proc.arguments = args
        
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = EnvironmentHelper.getAugmentedPath()
        env["PORT"] = String(activePort)
        env["HOST"] = "127.0.0.1"
        proc.environment = env
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        
        self.serverProcess = proc
        
        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            if let str = String(data: data, encoding: .utf8) {
                self.handleServerOutput(str, isError: false)
            }
        }
        
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            if let str = String(data: data, encoding: .utf8) {
                self.handleServerOutput(str, isError: true)
            }
        }
        
        proc.terminationHandler = { [weak self] p in
            guard let self = self else { return }
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            
            DispatchQueue.main.async {
                self.stopTimers()
                self.serverProcess = nil
                self.pid = nil
                self.isHealthy = false
                self.status = .stopped
                self.appendLog("[OmniRoute] Gateway process exited with status \(p.terminationStatus).", type: .info)
            }
        }
        
        do {
            try proc.run()
            self.pid = proc.processIdentifier
            self.startTimers()
            appendLog("[OmniRoute] Process started (PID: \(proc.processIdentifier))", type: .success)
        } catch {
            status = .error(error.localizedDescription)
            appendLog("[OmniRoute] Failed to run omniroute: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func handleServerOutput(_ chunk: String, isError: Bool) {
        serverOutputBuffer += chunk
        while let newlineRange = serverOutputBuffer.range(of: "\n") {
            let line = String(serverOutputBuffer[..<newlineRange.lowerBound])
            serverOutputBuffer.removeSubrange(...newlineRange.lowerBound)
            if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                appendLog(line, type: isError ? .stderr : .stdout)
            }
        }
    }
    
    func stopServer() {
        guard let proc = serverProcess, proc.isRunning else {
            status = .stopped
            pid = nil
            stopTimers()
            return
        }
        
        appendLog("[OmniRoute] Stopping gateway server...", type: .info)
        stopTimers()
        
        let pId = proc.processIdentifier
        kill(pId, SIGINT)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if proc.isRunning {
                kill(pId, SIGKILL)
            }
            DispatchQueue.main.async {
                self?.serverProcess = nil
                self?.pid = nil
                self?.isHealthy = false
                self?.status = .stopped
            }
        }
    }
    
    func restartServer() {
        stopServer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.startServer()
        }
    }
    
    private func startTimers() {
        stopTimers()
        
        uptimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.status == .running || self.status == .starting else { return }
            self.uptimeSeconds += 1
        }
        
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkGatewayHealth()
        }
    }
    
    private func stopTimers() {
        uptimeTimer?.invalidate()
        uptimeTimer = nil
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    private func checkGatewayHealth() {
        guard let url = URL(string: "http://127.0.0.1:\(activePort)") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.2
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let http = response as? HTTPURLResponse, http.statusCode > 0 {
                    let wasHealthy = self.isHealthy
                    self.isHealthy = true
                    if self.status == .starting {
                        self.status = .running
                        self.appendLog("[OmniRoute] Gateway is live and healthy at http://localhost:\(self.activePort)", type: .success)
                        if self.autoOpenBrowser && !wasHealthy {
                            self.openDashboard()
                        }
                    }
                } else if error != nil {
                    if self.status == .running {
                        self.isHealthy = false
                    }
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Actions
    func openDashboard() {
        guard let url = URL(string: "http://localhost:\(activePort)") else { return }
        NSWorkspace.shared.open(url)
    }
    
    func copyApiEndpoint() {
        let endpoint = "http://localhost:\(activePort)/v1"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(endpoint, forType: .string)
        appendLog("[Clipboard] Copied endpoint: \(endpoint)", type: .info)
    }
    
    func copySnippet(text: String, id: UUID) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        self.copiedSnippetId = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.copiedSnippetId == id {
                self?.copiedSnippetId = nil
            }
        }
    }
}
