# CardVault

CardVault is a SwiftUI iOS app for local-only secure card storage.

## Features
- Face ID / biometrics gate when app opens and when app returns from background.
- Sensitive data (`cardNumber`, `cvv`) stored in Keychain.
- Non-sensitive metadata encrypted at rest using `CryptoKit` (`AES.GCM`).
- No backend and no cloud sync.

## Requirements
- macOS with Xcode 26+.
- iPhone for on-device testing.
- Apple ID signed into Xcode.

## Project Structure
- `CardVault/Models`: domain models and DTOs.
- `CardVault/Services`: Keychain, biometric auth, encrypted storage, repository.
- `CardVault/ViewModels`: state + business logic for screens.
- `CardVault/Views`: SwiftUI screens.
- `CardVault/Components`: reusable UI pieces.
- `CardVault/Utilities`: formatting, validation, dependency wiring.
- `CardVault/Assets.xcassets`: app icons and colors.
- `CardVault.xcodeproj`: Xcode project file.

## Run In Xcode
1. Open `CardVault.xcodeproj`.
2. Select target `CardVault` -> `Signing & Capabilities`.
3. Enable `Automatically manage signing`.
4. Select your Apple team.
5. Connect iPhone and trust the Mac if prompted.
6. Select your iPhone as run destination.
7. Press `Run`.

## Install On iPhone (first time)
1. On iPhone, enable `Developer Mode`:
   `Settings > Privacy & Security > Developer Mode`.
2. If you see untrusted developer warning after install:
   `Settings > General > VPN & Device Management > Developer App > Trust`.

## Git: What To Push
Push these:
- `CardVault/`
- `CardVault.xcodeproj/` (except user-specific data)
- `.gitignore`
- `README.md`

Do not push these:
- `DerivedData/`
- `build/`
- `*.xcuserdatad`, `*.xcuserstate`, `xcuserdata/`
- Any local caches/logs

## Recommended First Commit Flow
```bash
git add .
git status
git commit -m "Set up CardVault project structure, docs, and ignore rules"
git push origin main
```
