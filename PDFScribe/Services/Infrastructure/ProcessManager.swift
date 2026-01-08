import Foundation

enum ProcessError: Error {
    case binaryNotFound
    case launchFailed
    case terminated
}

class ProcessManager {
    private var process: Process?
    private let binaryPath: String
    private let arguments: [String]
    
    var onStdout: ((Data) -> Void)?
    var onStderr: ((Data) -> Void)?
    var onTerminate: (() -> Void)?
    
    init(binaryPath: String, arguments: [String] = []) {
        self.binaryPath = binaryPath
        self.arguments = arguments
    }
    
    func launch() throws {
        guard FileManager.default.fileExists(atPath: binaryPath) else {
            throw ProcessError.binaryNotFound
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = arguments
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let stdinPipe = Pipe()
        
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = stdinPipe
        
        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                self?.onStdout?(data)
            }
        }
        
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                self?.onStderr?(data)
            }
        }
        
        process.terminationHandler = { [weak self] _ in
            self?.onTerminate?()
        }
        
        do {
            try process.run()
            self.process = process
        } catch {
            throw ProcessError.launchFailed
        }
    }
    
    func write(_ data: Data) throws {
        guard let stdin = process?.standardInput as? Pipe else {
            throw ProcessError.terminated
        }
        try stdin.fileHandleForWriting.write(contentsOf: data)
    }
    
    func terminate() {
        process?.terminate()
        process = nil
    }
    
    var isRunning: Bool {
        process?.isRunning ?? false
    }
}
