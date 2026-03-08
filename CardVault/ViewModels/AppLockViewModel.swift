import Foundation
import Combine

@MainActor
final class AppLockViewModel: ObservableObject {
    @Published private(set) var isUnlocked = false
    @Published private(set) var isAuthenticating = false
    @Published var errorMessage: String?

    private let authenticationService: AuthenticationServicing

    init(authenticationService: AuthenticationServicing) {
        self.authenticationService = authenticationService
    }

    func lock() {
        isUnlocked = false
    }

    func unlockIfNeeded() async {
        guard !isUnlocked else { return }
        await unlock()
    }

    func unlock() async {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            try await authenticationService.authenticate()
            isUnlocked = true
            errorMessage = nil
        } catch {
            isUnlocked = false
            errorMessage = error.localizedDescription
        }
    }
}
