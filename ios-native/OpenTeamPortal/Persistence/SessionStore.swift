import Foundation
import Security

protocol SessionStore {
    func currentToken() -> String?
    func save(token: String) throws
    func clear() throws
}

final class KeychainSessionStore: SessionStore {
    private let service = "com.openteam.portal.native"
    private let account = "portal-session-token"

    func currentToken() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func save(token: String) throws {
        let data = Data(token.utf8)
        var query = baseQuery()
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)

        if status == errSecSuccess {
            return
        }

        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw PortalError.backend("Unable to save session token.")
        }
    }

    func clear() throws {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

final class MemorySessionStore: SessionStore {
    private var token: String?

    func currentToken() -> String? {
        token
    }

    func save(token: String) throws {
        self.token = token
    }

    func clear() throws {
        token = nil
    }
}

