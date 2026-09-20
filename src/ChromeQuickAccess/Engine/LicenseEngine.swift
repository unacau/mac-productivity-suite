import Foundation
import Security
import os

@MainActor
public final class LicenseEngine: ObservableObject, @unchecked Sendable {
    public static let shared = LicenseEngine()
    
    public static let serviceName = "com.almosteleven.xomsky.license"
    public static let licenseAccount = "pro_license_key"
    public static let activationAccount = "pro_activation_id"
    public static let proPrice = "$19 Lifetime"
    public static let freeSlotsLimit = 5
    public static let freePinnedAppsLimit = 4 // 1 browser hub slot + 4 user pinned app slots = 5 free slots
    
    public static let polarCheckoutUrl = "https://buy.polar.sh/polar_cl_v5lBa882Ea4dkTo9gvABMVxVbMgRyjkkhUcY43ktCAo"
    public static let polarActivateEndpoint = "https://api.polar.sh/v1/customer-portal/license-keys/activate"
    public static let polarDeactivateEndpoint = "https://api.polar.sh/v1/customer-portal/license-keys/deactivate"
    public static let polarOrganizationId = "fabcbc99-df59-4b60-9485-20a8dddca3c3"
    
    public enum ActivationResult: Equatable, Sendable {
        case success
        case invalidKey(String)
        case activationLimitReached
        case networkError(String)
    }
    
    public static var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               ProcessInfo.processInfo.arguments.contains(where: { $0.contains(".xctest") || $0.contains("swift-testing") }) ||
               NSClassFromString("XCTestCase") != nil
    }
    
    private let logger = Logger(subsystem: "com.almosteleven.xomsky", category: "license")
    
    /// Test hook to override Pro status during automated unit tests
    public var testOverrideProStatus: Bool? = nil
    /// Test hook to mock online Polar activation responses in automated tests
    public var testMockOnlineValidationResult: Bool? = nil
    
    @Published private var internalIsPro: Bool = false
    @Published public private(set) var activeLicenseKey: String? = nil
    @Published public private(set) var activeActivationId: String? = nil
    
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
            self.activeActivationId = readKeychainActivationId() ?? UserDefaults.standard.string(forKey: "XomskyProActivationId")
            return
        }
        
        // 2. Fallback to UserDefaults (for sandboxed / headless test environments)
        if let fallbackKey = UserDefaults.standard.string(forKey: "XomskyProLicenseKey"),
           validateLicenseKey(fallbackKey) {
            self.internalIsPro = true
            self.activeLicenseKey = fallbackKey
            self.activeActivationId = UserDefaults.standard.string(forKey: "XomskyProActivationId")
            return
        }
        
        self.internalIsPro = false
        self.activeLicenseKey = nil
        self.activeActivationId = nil
    }
    
    public static func isOfflineMasterKey(_ key: String) -> Bool {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let prefixes = [
            "XOMSKY-OWNER-",
            "XOMSKY-VIP-",
            "XOMSKY-GIVEAWAY-",
            "KHOMYAK-OWNER-",
            "KHOMYAK-VIP-",
            "KHOMYAK-GIVEAWAY-"
        ]
        if prefixes.contains(where: { normalized.hasPrefix($0) }) {
            return true
        }
        if normalized == "XOMSKY-OWNER" || normalized == "XOMSKY-VIP" || normalized == "XOMSKY-GIVEAWAY" ||
           normalized == "KHOMYAK-OWNER" || normalized == "KHOMYAK-VIP" || normalized == "KHOMYAK-GIVEAWAY" {
            return true
        }
        return false
    }
    
    public func validateLicenseKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let upper = trimmed.uppercased()
        
        // 1. Offline master keys
        if Self.isOfflineMasterKey(trimmed) {
            return true
        }
        
        // 2. Polar customer keys (prefix XOMSKY- or legacy KHOMYAK-)
        if (upper.hasPrefix("XOMSKY-") || upper.hasPrefix("KHOMYAK-")) && trimmed.count >= 8 {
            return true
        }
        
        return false
    }
    
    public func validateWithPolar(key: String, timeout: TimeInterval = 5.0) -> Bool {
        if let mock = testMockOnlineValidationResult {
            return mock
        }
        
        // In headless tests without mock, don't execute unmocked network calls; fail explicitly
        if Self.isRunningTests && testMockOnlineValidationResult == nil {
            return false
        }
        
        guard let url = URL(string: Self.polarActivateEndpoint) else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Xomsky/1.0.0 (macOS)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        let label = Host.current().localizedName ?? "Mac"
        let payload: [String: Any] = [
            "key": key,
            "organization_id": Self.polarOrganizationId,
            "label": label
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            return false
        }
        request.httpBody = httpBody
        
        let semaphore = DispatchSemaphore(value: 0)
        var isSuccess = false
        var parsedActivationId: String? = nil
        
        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: OperationQueue())
        let task = session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            if let error = error {
                self.logger.error("Polar license activation network error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                isSuccess = true
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let aid = json["id"] as? String {
                    parsedActivationId = aid
                }
            } else {
                let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                self.logger.warning("Polar activation rejected with status \(httpResponse.statusCode): \(bodyString)")
            }
        }
        task.resume()
        
        _ = semaphore.wait(timeout: .now() + timeout)
        if isSuccess, let aid = parsedActivationId {
            _ = saveKeychainActivationId(id: aid)
            UserDefaults.standard.set(aid, forKey: "XomskyProActivationId")
            self.activeActivationId = aid
        }
        return isSuccess
    }
    
    public func activateOnlineDetailed(key: String) async -> ActivationResult {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateLicenseKey(trimmed) else {
            logger.warning("License activation rejected: invalid key format for '\(key)'.")
            return .invalidKey("Invalid key format. Xomsky license keys start with 'XOMSKY-'.")
        }
        
        if Self.isOfflineMasterKey(trimmed) {
            logger.info("Activating via offline master key: '\(trimmed)'.")
            _ = activateOffline(key: trimmed)
            return .success
        }
        
        if let mock = testMockOnlineValidationResult {
            if mock {
                _ = activateOffline(key: trimmed)
                return .success
            } else {
                return .invalidKey("License key rejected by validation service.")
            }
        }
        
        if Self.isRunningTests && testMockOnlineValidationResult == nil {
            return .invalidKey("No mock configured for online validation in automated test run.")
        }
        
        guard let url = URL(string: Self.polarActivateEndpoint) else {
            return .networkError("Invalid validation endpoint URL.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Xomsky/1.0.0 (macOS)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 8.0
        
        let label = Host.current().localizedName ?? "Mac"
        let payload: [String: Any] = [
            "key": trimmed,
            "organization_id": Self.polarOrganizationId,
            "label": label
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            return .networkError("Failed to serialize activation payload.")
        }
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .networkError("Invalid server response.")
            }
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                var activationId: String? = nil
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let aid = json["id"] as? String {
                    activationId = aid
                }
                _ = activateOffline(key: trimmed, activationId: activationId)
                return .success
            } else if httpResponse.statusCode == 403 || httpResponse.statusCode == 400 {
                let body = String(data: data, encoding: .utf8) ?? ""
                if body.lowercased().contains("limit") || body.lowercased().contains("maximum") {
                    return .activationLimitReached
                } else {
                    return .invalidKey("This license key could not be activated (\(httpResponse.statusCode)).")
                }
            } else if httpResponse.statusCode == 404 {
                return .invalidKey("License key not found. Please verify the key entered.")
            } else {
                let body = String(data: data, encoding: .utf8) ?? ""
                logger.warning("Polar async activation rejected (\(httpResponse.statusCode)): \(body)")
                return .invalidKey("Validation error (\(httpResponse.statusCode)).")
            }
        } catch {
            logger.error("Polar async activation error: \(error.localizedDescription)")
            return .networkError(error.localizedDescription)
        }
    }
    
    public func activateOnline(key: String) async -> Bool {
        return await activateOnlineDetailed(key: key) == .success
    }
    
    @discardableResult
    public func activate(key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateLicenseKey(trimmed) else {
            logger.warning("License activation rejected: invalid key format for '\(key)'.")
            return false
        }
        
        // 1. Offline master key: activate immediately without network
        if Self.isOfflineMasterKey(trimmed) {
            logger.info("Activating via offline master key: '\(trimmed)'.")
            return activateOffline(key: trimmed)
        }
        
        // 2. Customer key: validate with Polar endpoint
        let valid = validateWithPolar(key: trimmed)
        guard valid else {
            logger.warning("License validation failed via Polar endpoint for '\(key)'.")
            return false
        }
        
        return activateOffline(key: trimmed, activationId: self.activeActivationId)
    }
    
    private func activateOffline(key: String, activationId: String? = nil) -> Bool {
        _ = saveKeychainLicense(key: key)
        UserDefaults.standard.set(key, forKey: "XomskyProLicenseKey")
        if let aid = activationId {
            _ = saveKeychainActivationId(id: aid)
            UserDefaults.standard.set(aid, forKey: "XomskyProActivationId")
            self.activeActivationId = aid
        }
        self.testOverrideProStatus = nil
        self.internalIsPro = true
        self.activeLicenseKey = key
        logger.info("Xomsky Pro activated successfully with key: '\(key)'!")
        return true
    }
    
    public func deactivate() {
        if let key = activeLicenseKey, let aid = activeActivationId, !Self.isOfflineMasterKey(key) {
            deactivateOnPolar(key: key, activationId: aid)
        }
        deleteKeychainLicense()
        deleteKeychainActivationId()
        UserDefaults.standard.removeObject(forKey: "XomskyProLicenseKey")
        UserDefaults.standard.removeObject(forKey: "XomskyProActivationId")
        self.testOverrideProStatus = nil
        self.internalIsPro = false
        self.activeLicenseKey = nil
        self.activeActivationId = nil
        logger.info("Xomsky Pro deactivated.")
    }
    
    private func deactivateOnPolar(key: String, activationId: String) {
        guard let url = URL(string: Self.polarDeactivateEndpoint) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Xomsky/1.0.0 (macOS)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 5.0
        
        let payload: [String: Any] = [
            "key": key,
            "organization_id": Self.polarOrganizationId,
            "activation_id": activationId
        ]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = httpBody
        
        let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: OperationQueue())
        session.dataTask(with: request) { [logger] _, response, error in
            if let error = error {
                logger.warning("Polar deactivation notice: \(error.localizedDescription)")
            } else if let http = response as? HTTPURLResponse {
                logger.info("Polar deactivation status: \(http.statusCode)")
            }
        }.resume()
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
    
    public func readKeychainActivationId() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.activationAccount,
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
    
    public func saveKeychainActivationId(id: String) -> Bool {
        guard let data = id.data(using: .utf8) else { return false }
        
        deleteKeychainActivationId()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.activationAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    public func deleteKeychainActivationId() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: Self.activationAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
