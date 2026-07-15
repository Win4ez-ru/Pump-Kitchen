import Foundation
import Security

protocol AuthTokenStore: AnyObject {
    var accessToken: String? { get }
    func save(accessToken: String) throws
    func clear() throws
}

final class KeychainAuthTokenStore: AuthTokenStore {
    private let service = "com.pumpkitchen.auth"
    private let account = "accessToken"
    private let accessible = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    var accessToken: String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func save(accessToken: String) throws {
        var query = baseQuery
        query[kSecValueData as String] = Data(accessToken.utf8)
        query[kSecAttrAccessible as String] = accessible

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updateAttributes: [String: Any] = [
                kSecValueData as String: Data(accessToken.utf8),
                kSecAttrAccessible as String: accessible
            ]
            let updateStatus = SecItemUpdate(baseQuery as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw AuthTokenStoreError.keychain(operation: .update, status: updateStatus)
            }
        default:
            throw AuthTokenStoreError.keychain(operation: .add, status: addStatus)
        }
    }

    func clear() throws {
        try clearIgnoringMissing()
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func clearIgnoringMissing() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthTokenStoreError.keychain(operation: .delete, status: status)
        }
    }
}

enum AuthTokenStoreError: LocalizedError {
    case keychain(operation: KeychainOperation, status: OSStatus)

    var errorDescription: String? {
        userMessage
    }

    var userMessage: String {
        switch self {
        case .keychain(let operation, _):
            operation.userMessage
        }
    }

    var failureReason: String? {
        switch self {
        case .keychain(let operation, let status):
            "Keychain \(operation.rawValue) failed with OSStatus \(status): \(Self.statusMessage(for: status))."
        }
    }

    var recoverySuggestion: String? {
        "Try again. If the problem continues, reinstall the app or check Keychain access for this build."
    }

    var diagnosticsDescription: String {
        switch self {
        case .keychain(let operation, let status):
            "Auth token Keychain \(operation.rawValue) failed. OSStatus=\(status), message=\(Self.statusMessage(for: status))"
        }
    }

    private static func statusMessage(for status: OSStatus) -> String {
        SecCopyErrorMessageString(status, nil) as String? ?? "No Keychain message available."
    }
}

enum KeychainOperation: String {
    case add = "add"
    case update = "update"
    case delete = "delete"

    var userMessage: String {
        switch self {
        case .add, .update:
            "Не удалось сохранить сессию. Попробуйте войти снова."
        case .delete:
            "Не удалось очистить сессию. Попробуйте ещё раз."
        }
    }
}
