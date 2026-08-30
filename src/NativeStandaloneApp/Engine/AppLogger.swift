import Foundation
import os.log

public enum LogCategory: String {
    case config = "Config"
    case discovery = "AppDiscovery"
    case engine = "AppSwitcherEngine"
    case browser = "BrowserProfiles"
    case hotkeys = "Hotkeys"
    case ui = "UI"
    case actions = "ProductivityActions"
    case generic = "Generic"
}

public struct AppLogger {
    public static let subsystem = "com.macproductivity.suite"
    
    public static func getLogger(category: LogCategory) -> os.Logger {
        return os.Logger(subsystem: subsystem, category: category.rawValue)
    }
}
