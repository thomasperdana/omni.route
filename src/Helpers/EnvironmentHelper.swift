import Foundation

struct EnvironmentHelper {
    private static var cachedAugmentedPath: String?
    
    static func getAugmentedPath() -> String {
        if let cached = cachedAugmentedPath {
            return cached
        }
        
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var candidatePaths = [
            "\(home)/.local/bin",
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "\(home)/.bun/bin",
            "\(home)/.cargo/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
        
        // Scan NVM node versions
        let nvmDir = "\(home)/.nvm/versions/node"
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmDir) {
            for v in versions {
                candidatePaths.append("\(nvmDir)/\(v)/bin")
            }
        }
        
        // Include system environment PATH
        if let sysPath = ProcessInfo.processInfo.environment["PATH"] {
            candidatePaths.append(contentsOf: sysPath.split(separator: ":").map(String.init))
        }
        
        // Query user's login shell PATH if possible
        if let shellPath = queryShellPath() {
            candidatePaths.append(contentsOf: shellPath.split(separator: ":").map(String.init))
        }
        
        var seen = Set<String>()
        var finalPaths: [String] = []
        for p in candidatePaths {
            if !seen.contains(p) && FileManager.default.fileExists(atPath: p) {
                seen.insert(p)
                finalPaths.append(p)
            }
        }
        
        let result = finalPaths.joined(separator: ":")
        cachedAugmentedPath = result
        return result
    }
    
    private static func queryShellPath() -> String? {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-l", "-c", "echo $PATH"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                return output
            }
        } catch {
            return nil
        }
        return nil
    }
    
    static func findExecutable(_ name: String, customPath: String? = nil) -> String? {
        if let custom = customPath, !custom.isEmpty {
            let expanded = (custom as NSString).expandingTildeInPath
            if FileManager.default.isExecutableFile(atPath: expanded) {
                return expanded
            }
        }
        
        let pathEnv = getAugmentedPath()
        let dirs = pathEnv.split(separator: ":").map(String.init)
        for dir in dirs {
            let fullPath = "\(dir)/\(name)"
            if FileManager.default.isExecutableFile(atPath: fullPath) {
                return fullPath
            }
        }
        return nil
    }
    
    static func runCommandSync(executable: String, arguments: [String]) -> (status: Int32, output: String) {
        let task = Process()
        task.launchPath = executable
        task.arguments = arguments
        
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = getAugmentedPath()
        task.environment = env
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return (task.terminationStatus, output)
        } catch {
            return (-1, error.localizedDescription)
        }
    }
    
    static func checkNode() -> (installed: Bool, path: String?, version: String?) {
        guard let path = findExecutable("node") else {
            return (false, nil, nil)
        }
        let res = runCommandSync(executable: path, arguments: ["--version"])
        return (res.status == 0, path, res.output)
    }
    
    static func checkNpm() -> (installed: Bool, path: String?, version: String?) {
        guard let path = findExecutable("npm") else {
            return (false, nil, nil)
        }
        let res = runCommandSync(executable: path, arguments: ["--version"])
        return (res.status == 0, path, res.output)
    }
    
    static func checkOmniroute() -> (installed: Bool, path: String?, version: String?) {
        guard let path = findExecutable("omniroute") else {
            return (false, nil, nil)
        }
        let res = runCommandSync(executable: path, arguments: ["--version"])
        let versionStr = res.status == 0 && !res.output.isEmpty ? res.output : "Installed"
        return (true, path, versionStr)
    }
}
