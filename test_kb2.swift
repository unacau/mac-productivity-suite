import Foundation

func checkKarabinerDaemon() -> Bool {
    let task = Process()
    task.launchPath = "/usr/bin/pgrep"
    task.arguments = ["-f", "Karabiner-Core-Service|Karabiner-Console-User-Server"]
    let pipe = Pipe()
    task.standardOutput = pipe
    do {
        try task.run()
        task.waitUntilExit()
        return task.terminationStatus == 0
    } catch {}
    return false
}
print(checkKarabinerDaemon())
