import Cocoa

@main
struct AppRunner {
    static func main() {
        if NSClassFromString("XCTest") != nil ||
           ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
           ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
           ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"] != nil {
            print("Running in test environment, skipping NSApplication event loop.")
            return
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
