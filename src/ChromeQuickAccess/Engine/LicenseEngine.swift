import Foundation
import Security
import os

@MainActor
public final class LicenseEngine: ObservableObject, @unchecked Sendable {
    public static let shared = LicenseEngine()
    
    public static let serviceName = "com.almosteleven.xomsky.license"
    public static let licenseAccount = "pro_license_key"
    public static let proPrice = "$19 Lifetime"
    public static let freeSlotsLimit = 5
    public static let freePinnedAppsLimit = 4 // 1 browser hub slot + 4 user pinned app slots = 5 free slots
    
    private let logger = Logger(subsystem: "com.almosteleven.xomsky", category: "license")
    
    /// Test hook to override Pro status during automated unit tests
    public var testOverrideProStatus: Bool? = nil
    
    @Published private var internalIsPro: Bool = false
    @Published public private(set) var activeLicenseKey: String? = nil
    
    public var isPro: Bool {
        if let override = testOverrideProStatus {
            return override
        }
        return internalIsPro
    }
    
    public init() {
        checkLicenseStatus()
    }
    
    public func checkLicenseStatus() {
        if let override = testOverrideProStatus {
            self.internalIsPro = override
            return
        }
        
        // 1. Try reading from macOS Keychain
        if let key = readKeychainLicense(), validateLicenseKey(key) {
            self.internalIsPro = true
            self.activeLicenseKey = key
            return
        }
        
        // 2. Fallback to UserDefaults (for sandboxed / headless test environments)
        if let fallbackKey = UserDefaults.standard.string(forKey: "XomskyProLicenseKey"),
           validateLicenseKey(fallbackKey) {
            self.internalIsPro = true
            self.activeLicenseKey = fallbackKey
            return
        }
        
        self.internalIsPro = false
        self.activeLicenseKey = nil
    }
    
    public func validateLicenseKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // Accept valid license key formats:
        // Format: XOMSKY-PRO-..., standard alphanumeric license keys, UUIDs, or keys with length >= 8
        return trimmed.count >= 8
    }
    
    @discardableResult
    public func activate(key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateLicenseKey(trimmed) else {
            logger.warning("License activation rejected: invalid key format for '\(key)'.")
            return false
        }
        
        _ = saveKeychainLicense(key: trimmed)
        UserDefaults.standard.set(trimmed, forKey: "XomskyProLicenseKey")
        self.testOverrideProStatus = nil
        self.internalIsPro = true
        self.activeLicenseKey = trimmed
        logger.info("Xomsky Pro activated successfully!")
        return true
    }
    
    public func deactivate() {
        deleteKeychainLicense()
        UserDefaults.standard.removeObject(forKey: "XomskyProLicenseKey")
        self.testOverrideProStatus = nil
        self.internalIsPro = false
        self.activeLicenseKey = nil
        logger.info("Xomsky Pro deactivated.")
    }
    
    // MARK: - Keychain Operations
    public func readKeychainLicense() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.licenseAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    public func saveKeychainLicense(key: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        
        deleteKeychainLicense()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.licenseAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    public func deleteKeychainLicense() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.licenseAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
