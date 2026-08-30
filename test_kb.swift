import Foundation

func checkKarabinerDaemon() -> Bool {
    let task = Process()
    task.launchPath = "/bin/ps"
    task.arguments = ["ax"]
    let pipe = Pipe()
    task.standardOutput = pipe
    do {
        try task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return output.contains("Karabiner-Core-Service") || output.contains("Karabiner-Console-User-Server")
        }
    } catch {}
    return false
}

print(checkKarabinerDaemon())
