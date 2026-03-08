import Foundation

@MainActor
final class AppDependencies {
    let authenticationService: AuthenticationServicing
    let repository: CardRepositoryProtocol

    init(authenticationService: AuthenticationServicing, repository: CardRepositoryProtocol) {
        self.authenticationService = authenticationService
        self.repository = repository
    }

    static func live() -> AppDependencies {
        let keychain = KeychainService()
        let metadataStore: EncryptedMetadataStore

        do {
            metadataStore = try EncryptedMetadataStore(keychain: keychain)
        } catch {
            fatalError("Failed to create encrypted metadata store: \(error.localizedDescription)")
        }

        let repository = CardRepository(keychain: keychain, metadataStore: metadataStore)
        let authentication = AuthenticationService()
        return AppDependencies(authenticationService: authentication, repository: repository)
    }
}
