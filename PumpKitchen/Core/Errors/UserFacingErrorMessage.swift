import Foundation

enum UserFacingErrorMessage {
    static func auth(_ error: Error) -> String {
        if let tokenStoreError = error as? AuthTokenStoreError {
            return tokenStoreError.userMessage
        }

        if isConnectivityError(error) {
            return "Backend недоступен."
        }

        return "Не удалось войти. Проверьте данные и попробуйте снова."
    }

    static func recipes(_ error: Error) -> String {
        if isConnectivityError(error) {
            return "Backend недоступен."
        }

        return "Рецепты сейчас не загрузились, попробуйте позже."
    }

    static func storage(_ error: Error) -> String {
        if isConnectivityError(error) {
            return "Backend недоступен."
        }

        return "Данные сейчас не загрузились, попробуйте позже."
    }

    static func profileSync(_ error: Error) -> String {
        if isConnectivityError(error) {
            return "Сохранено локально. Backend недоступен."
        }

        return "Сохранено локально. Профиль не синхронизировался, попробуйте позже."
    }

    private static func isConnectivityError(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }

        switch error {
        case AuthError.invalidBackendURL, AuthError.invalidResponse:
            return true
        case BackendRecipeGenerationError.invalidBaseURL,
             BackendRecipeGenerationError.authenticationRequired:
            return true
        default:
            return false
        }
    }
}
