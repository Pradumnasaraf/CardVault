<p align="center">
  <img src="https://github.com/user-attachments/assets/3dffe5a2-2d65-4330-aa63-6109def681ff" alt="CardVault Logo" width="120" />
</p>

# CardVault

CardVault is a clean, secure iOS card wallet built for local-first privacy. Your card data stays on your iPhone and is never uploaded to a backend or cloud service.

<p align="center">
  <img src="https://github.com/user-attachments/assets/98858d33-0360-45be-8387-20aefbfed294" alt="screenshot-1" width="170" />
  &nbsp;
  <img src="https://github.com/user-attachments/assets/61f0dcc4-68e3-4b94-a93b-f23d9846ad49" alt="screenshot-2" width="170" />
  &nbsp;
  <img src="https://github.com/user-attachments/assets/dd30a5f2-79b8-46da-b9df-637a96015115" alt="screenshot-3" width="170" />
  &nbsp;
  <img src="https://github.com/user-attachments/assets/c82b696a-dc67-485a-95c1-494c55784e00" alt="screenshot-4" width="170" />
</p>

## Why CardVault

- Local-first: no backend, no cloud sync
- Face ID protected for sensitive actions
- Fast access with a modern card UI
- Card provider logos, notes, and cardholder name support
- Copy card number, expiry, and CVV with one tap

## Privacy & Security

- Sensitive values (`cardNumber`, `cvv`) are stored in iOS Keychain.
- Metadata is encrypted at rest using `CryptoKit` (`AES.GCM`).
- All data stays on-device and local to your iPhone.
- CardVault does not require an account and does not send card data to external servers.

## Getting Started

1. Open `CardVault.xcodeproj` in Xcode.
2. Set your signing team in `Signing & Capabilities`.
3. Connect your iPhone and choose it as the run destination.
4. Build and run.

## License

Licensed under Apache-2.0. See [LICENSE](LICENSE).
