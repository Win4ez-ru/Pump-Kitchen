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
        try clearIgnoringMissing()
        var query = baseQuery
        query[kSecValueData as String] = Data(accessToken.utf8)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw AuthTokenStoreError.keychain(status) }
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
            throw AuthTokenStoreError.keychain(status)
        }
    }
}

enum AuthTokenStoreError: Error {
    case keychain(OSStatus)
}
