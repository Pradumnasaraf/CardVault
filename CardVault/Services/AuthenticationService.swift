import Foundation
import LocalAuthentication

enum AuthenticationError: LocalizedError {
    case unavailable
    case notFaceID
    case failed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Biometric authentication is unavailable on this device."
        case .notFaceID:
            return "Face ID is required for CardVault."
        case .failed:
            return "Authentication failed."
        }
    }
}

protocol AuthenticationServicing {
    func authenticate() async throws
}

final class AuthenticationService: AuthenticationServicing {
    func authenticate() async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
            throw AuthenticationError.unavailable
        }

        guard context.biometryType == .faceID else {
            throw AuthenticationError.notFaceID
        }

        let reason = "Unlock CardVault"
        let success = await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }

        guard success else {
            throw AuthenticationError.failed
        }
    }
}
