import CryptoKit
import Foundation

protocol CardMetadataStoring {
    func load() throws -> [CardMetadata]
    func save(_ metadata: [CardMetadata]) throws
}

final class EncryptedMetadataStore: CardMetadataStoring {
    private let keychain: KeychainServicing
    private let encryptionKeyName = "cardvault.metadata.encryption.key"
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(keychain: KeychainServicing) throws {
        self.keychain = keychain
        self.fileURL = try Self.makeFileURL()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws -> [CardMetadata] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let encryptedData = try Data(contentsOf: fileURL)
        let key = try fetchOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        return try decoder.decode([CardMetadata].self, from: decrypted)
    }

    func save(_ metadata: [CardMetadata]) throws {
        let payload = try encoder.encode(metadata)
        let key = try fetchOrCreateKey()
        let sealed = try AES.GCM.seal(payload, using: key)

        guard let combined = sealed.combined else {
            throw CocoaError(.coderInvalidValue)
        }

        try combined.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    private func fetchOrCreateKey() throws -> SymmetricKey {
        if let data = try keychain.read(encryptionKeyName) {
            return SymmetricKey(data: data)
        }

        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        try keychain.save(data, for: encryptionKeyName)
        return key
    }

    private static func makeFileURL() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let directory = baseURL.appendingPathComponent("CardVault", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return directory.appendingPathComponent("card_metadata.enc")
    }
}
