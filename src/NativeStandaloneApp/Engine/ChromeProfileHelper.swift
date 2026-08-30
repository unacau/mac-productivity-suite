import Cocoa

struct ChromeProfileSpec {
    let index: Int
    let dir: String
    let name: String
}

final class ChromeProfileHelper {
    static let shared = ChromeProfileHelper()
    
    let profiles: [ChromeProfileSpec] = [
        ChromeProfileSpec(index: 1, dir: "Default", name: "Igor"),
        ChromeProfileSpec(index: 2, dir: "Profile 2", name: "Igor (Al11)"),
        ChromeProfileSpec(index: 3, dir: "Profile 5", name: "Igor (GCP Free Trial)"),
        ChromeProfileSpec(index: 4, dir: "Profile 1", name: "Nastya")
    ]
    
    private init() {}
    
    func focusProfile(index: Int) {
        guard let p = profiles.first(where: { $0.index == index }) else { return }
        
        // Fast launch/focus via open -b com.google.Chrome --args --profile-directory=...
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-b", "com.google.Chrome", "--args", "--profile-directory=\(p.dir)"]
        try? task.run()
        
        // Also ensure Chrome is frontmost
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let apps = NSWorkspace.shared.runningApplications
            if let chrome = apps.first(where: { $0.bundleIdentifier == "com.google.Chrome" }) {
                chrome.activate()
            }
        }
    }
}
